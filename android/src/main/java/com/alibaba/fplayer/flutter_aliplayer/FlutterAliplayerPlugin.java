package com.alibaba.fplayer.flutter_aliplayer;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.aliyun.player.AliPlayerFactory;
import com.aliyun.player.AliPlayerGlobalSettings;
import com.aliyun.player.IPlayer;
import com.aliyun.player.VidPlayerConfigGen;
import com.aliyun.private_service.PrivateService;
import com.cicada.player.utils.Logger;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * FlutterAliplayerPlugin
 */
public class FlutterAliplayerPlugin extends PlatformViewFactory implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, FlutterAliPlayerView.FlutterAliPlayerViewListener, ActivityAware {
    private static final String TAG = "FlutterAliplayerPlugin";

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private FlutterAliDownloader mDownloaderPlugin;
    private FlutterAliPlayerGlobalSettings mAliPlayerGlobalSettings;
    private FlutterAliMediaLoader mMediaLoaderPlugin;
    private FlutterAliMediaLoaderV2 mMediaLoaderV2Plugin;
    private FlutterPluginBinding flutterPluginBinding;

    private Map<String, FlutterAliPlayer> mFlutterAliPlayerMap = new HashMap<>();
    private Map<String, FlutterAliListPlayer> mFlutterAliListPlayerMap = new HashMap<>();
    private Map<String, FlutterAliLiveShiftPlayer> mFlutterAliLiveShiftPlayerMap = new HashMap<>();
    private Map<Integer, FlutterAliPlayerView> mFlutterAliPlayerViewMap = new HashMap<>();
    private MethodChannel mMethodChannel;
    private EventChannel.EventSink mEventSink;
    private EventChannel mEventChannel;
    private Integer playerType = -1; // 播放器类型
    private Context mContext;
    private static final Handler sMainHandler = new Handler(Looper.getMainLooper());
    private FlutterAliFloatWindowManager mAliFloatWindowManager;
    private VidPlayerConfigGen mVidPlayerConfigGen;
    private Activity mBindActivity;// 获取可用的Activity
    private Logger.OnLogCallback mOnLogCallback;

    public FlutterAliplayerPlugin() {
        super(StandardMessageCodec.INSTANCE);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding;
        //上下文
        this.mContext = flutterPluginBinding.getApplicationContext();

        // 根据依赖变量判断是否加载 Rts 库
        checkAvailableRts();

        // 声明业务场景
        AliPlayerGlobalSettings.setOption(AliPlayerGlobalSettings.SET_EXTRA_DATA, FlutterAliPlayerUtils.sdkVersion());

        // 加载功能模块
        loadPlugin();

        // 初始化通道
        initChannel();

        // 默认实现 setCacheUrlHashCallback
        AliPlayerGlobalSettings.setCacheUrlHashCallback(new AliPlayerGlobalSettings.OnGetUrlHashCallback() {
            @Override
            public String getUrlHashCallback(String s) {
                if (s.contains("Ciphertext")) {
                    return FlutterAliPlayerStringUtils.stringToMD5(s);
                }
                String result = s;
                if (s.contains("?")) {
                    String[] split = s.split("\\?");
                    result = split[0];
                }
                return FlutterAliPlayerStringUtils.stringToMD5(result);
            }
        });
    }


    /**
     * 加载并初始化各个功能插件模块
     * 包括视图工厂注册、下载器、媒体加载器、全局设置和悬浮窗管理器等组件
     */
    private void loadPlugin() {
        // 注册平台视图工厂，用于创建播放器渲染视图
        // 视图标识符: flutter_aliplayer_render_view
        flutterPluginBinding.getPlatformViewRegistry().registerViewFactory("flutter_aliplayer_render_view", this);

        // 初始化下载管理器插件，用于处理视频下载相关功能
        if (null == mDownloaderPlugin) {
            mDownloaderPlugin = new FlutterAliDownloader();
        }
        mDownloaderPlugin.onAttachedToModule(flutterPluginBinding);

        // 初始化媒体预加载插件，用于提前加载媒体资源
        if (mMediaLoaderPlugin == null) {
            mMediaLoaderPlugin = new FlutterAliMediaLoader();
        }
        mMediaLoaderPlugin.onAttachedToModule(flutterPluginBinding);

        // 初始化媒体预加载V2插件，用于提前加载媒体资源
        if (mMediaLoaderV2Plugin == null) {
            mMediaLoaderV2Plugin = new FlutterAliMediaLoaderV2();
        }
        mMediaLoaderV2Plugin.onAttachedToModule(flutterPluginBinding);

        // 初始化全局设置插件，用于配置播放器全局参数
        mAliPlayerGlobalSettings = new FlutterAliPlayerGlobalSettings(flutterPluginBinding.getApplicationContext(), flutterPluginBinding);

        // 初始化悬浮窗管理器，用于实现播放器悬浮窗功能
        // TODO: "Please confirm whether this feature is still needed. If not, we plan to remove this class in a future update."
        mAliFloatWindowManager = new FlutterAliFloatWindowManager(flutterPluginBinding.getApplicationContext());

    }


    /**
     * 初始化Flutter与原生Android之间的通信通道
     * 包括方法调用通道和事件流通道
     */
    private void initChannel() {
        // 创建方法调用通道，用于处理来自Flutter的API调用请求
        // 通道名称: plugins.flutter_aliplayer_factory
        mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "plugins.flutter_aliplayer_factory");
        // 设置当前类为方法调用处理器，处理Flutter发送过来的方法调用
        mMethodChannel.setMethodCallHandler(this);

        // 创建事件流通道，用于向Flutter发送播放器事件回调
        // 通道名称: flutter_aliplayer_event
        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_aliplayer_event");
        // 设置当前类为事件流处理器，处理事件的监听和取消监听
        mEventChannel.setStreamHandler(this);
    }


    /**
     * 销毁插件通道
     *
     * @param binding 插件绑定对象
     */
    private void destroyPluginChannel(FlutterPluginBinding binding) {
        if (null != mMediaLoaderV2Plugin) {
            mMediaLoaderV2Plugin.onDetachedFromModule(binding);
            mMediaLoaderV2Plugin = null;
        }

        if (null != mMediaLoaderPlugin) {
            mMediaLoaderPlugin.onDetachedFromModule(binding);
            mMediaLoaderPlugin = null;
        }


        if (null != mDownloaderPlugin) {
            mDownloaderPlugin.onDetachedFromModule(flutterPluginBinding);
            mDownloaderPlugin = null;
        }


        // 创建方法调用通道，用于处理来自Flutter的API调用请求
        // 通道名称: plugins.flutter_aliplayer_factory
        if (null != mMethodChannel) {
            mMethodChannel.setMethodCallHandler(null);
            mMethodChannel = null;
        }

        // 创建事件流通道，用于向Flutter发送播放器事件回调
        // 通道名称: flutter_aliplayer_event
        if (null != mEventChannel) {
            mEventChannel.setStreamHandler(null);
            mEventChannel = null;
        }

        // 悬浮窗管理器销毁
        if (null != mAliFloatWindowManager) {
            mAliFloatWindowManager.destroy();
            mAliFloatWindowManager = null;
        }

        // 销毁 Setting管理器
        if (null != mAliPlayerGlobalSettings) {
            mAliPlayerGlobalSettings.destroy();
        }
    }


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "showFloatViewForAndroid": {
                int showFloatViewId = (int) call.arguments;
                FlutterAliPlayerView showFlutterAliPlayerView = mFlutterAliPlayerViewMap.get(showFloatViewId);
                if (checkFloatWindowPermission()) {
                    if (null != showFlutterAliPlayerView && !showFlutterAliPlayerView.isDisplayView() && null != mAliFloatWindowManager) {
                        mAliFloatWindowManager.showFloatWindow(showFlutterAliPlayerView);
                        result.success(null);
                    } else {
                        result.error("not support", "the current playerView viewType(AliDisPlayView) is not support showFloatWindow", null);
                    }
                } else {
                    result.error("NO_PERMISSION", "Permission denied", null);
                }
            }
            break;
            case "hideFloatViewForAndroid": {
                if (null != mAliFloatWindowManager) {
                    mAliFloatWindowManager.hideFloatWindow();
                }
                result.success(null);
            }
            break;
            case "checkFloatViewPermission": {
                result.success(checkFloatWindowPermission());
            }
            break;
            case "requestFloatViewPermission": {
                if (!checkFloatWindowPermission()) {
                    if (null != mBindActivity) {
                        requestFloatWindowPermission(mBindActivity);
                        result.success(false); // 表示“已发起请求，但尚未确认”
                    } else {
                        result.error("NO_ACTIVITY", "Activity is not available", null);
                    }
                } else {
                    result.success(true);
                }
            }
            break;
            case "setFloatViewUI": {
                Boolean isVisible = (Boolean) call.arguments;
                if (null != mAliFloatWindowManager) {
                    mAliFloatWindowManager.setUIVisible(isVisible);
                }
                result.success(null);
            }
            break;
            case "setFloatViewIcon": {
                // 获取本地文件或者网络地址
                String closeButtonAsset = call.argument("closeButton");
                String backButtonAsset = call.argument("backButton");
                if (null != mAliFloatWindowManager) {
                    if (null != closeButtonAsset && !closeButtonAsset.isEmpty()) {
                        mAliFloatWindowManager.setCloseButtonIcon(loadFlutterAsset(closeButtonAsset));
                    }

                    if (null != backButtonAsset && !backButtonAsset.isEmpty()) {
                        mAliFloatWindowManager.setBackButtonIcon(loadFlutterAsset(backButtonAsset));
                    }
                }
                result.success(null);
            }
            break;
            case "createAliPlayer": {
                playerType = call.argument("arg");
                if (0 == playerType) {
                    //AliPlayer
                    String createPlayerId = call.argument("playerId");
                    FlutterAliPlayer flutterAliPlayer = new FlutterAliPlayer(flutterPluginBinding, createPlayerId);
                    initListener(flutterAliPlayer);
                    mFlutterAliPlayerMap.put(createPlayerId, flutterAliPlayer);
                } else if (1 == playerType) {
                    String createPlayerId = call.argument("playerId");
                    //AliListPlayer
                    FlutterAliListPlayer mFlutterAliListPlayer = new FlutterAliListPlayer(flutterPluginBinding, createPlayerId);
                    initListener(mFlutterAliListPlayer);
                    mFlutterAliListPlayerMap.put(createPlayerId, mFlutterAliListPlayer);
                } else if (2 == playerType) {
                    //AliLiveShiftPlayer
                    String createPlayerId = call.argument("playerId");
                    FlutterAliLiveShiftPlayer flutterAliLiveShiftPlayer = new FlutterAliLiveShiftPlayer(flutterPluginBinding, createPlayerId);
                    initListener(flutterAliLiveShiftPlayer);
                    mFlutterAliLiveShiftPlayerMap.put(createPlayerId, flutterAliLiveShiftPlayer);
                }
                result.success(null);
            }
            break;
            case "initService": {
                byte[] data = (byte[]) call.arguments;
                PrivateService.initService(flutterPluginBinding.getApplicationContext(), data);
                result.success(null);
            }
            break;
            case "loadRtsLibrary": {
                Boolean isAliPlayerSDK = (Boolean) call.arguments;
                if (isAliPlayerSDK) {
                    System.loadLibrary("RtsSDK");
                }
                result.success(null);
            }
            break;
            case "getSDKVersion":
                result.success(AliPlayerFactory.getSdkVersion());
                break;
            case "getDeviceUUID":
                result.success(AliPlayerFactory.getDeviceUUID());
                break;
            case "getLogLevel":
                result.success(getLogLevel());
                break;
            case "enableConsoleLog":
                Boolean enableLog = (Boolean) call.arguments;
                enableConsoleLog(enableLog);
                result.success(null);
                break;
            case "setLogLevel":
                Integer level = (Integer) call.arguments;
                setLogLevel(level);
                result.success(null);
                break;
            case "setLogInfoBlock":
                boolean isEnable = false;
                if (call.hasArgument("arg")) {
                    isEnable = Boolean.TRUE.equals(call.argument("arg"));
                }
                setOnLogCallback(isEnable);
                result.success(null);
                break;
            case "setLogOption":
                Integer option = (Integer) call.arguments;
                Logger.getInstance(mContext).setLogOption(Logger.LogOption.FRAME_LEVEL_LOGGING_ENABLED, option);
                result.success(null);
                break;
            case "createDeviceInfo":
                result.success(createDeviceInfo());
                break;
            case "addBlackDevice":
                Map<String, String> addBlackDeviceMap = call.arguments();
                if (addBlackDeviceMap != null) {
                    String typeObj = addBlackDeviceMap.get("black_type");
                    String deviceObj = addBlackDeviceMap.get("black_device");

                    // 确保非 null 且是 String 类型
                    if (typeObj != null && deviceObj != null) {
                        addBlackDevice(typeObj, deviceObj);
                    }
                }
                result.success(null);
                break;
            case "setPlayerView": {
                Integer viewId = (Integer) call.argument("arg");
                String playerId = call.argument("playerId");
                FlutterAliPlayerView flutterAliPlayerView = mFlutterAliPlayerViewMap.get(viewId);
                FlutterPlayerBase mPlayer = null;

                if (null != mFlutterAliPlayerMap.get(playerId)) {
                    mPlayer = mFlutterAliPlayerMap.get(playerId);
                } else if (null != mFlutterAliListPlayerMap.get(playerId)) {
                    mPlayer = mFlutterAliListPlayerMap.get(playerId);
                } else if (null != mFlutterAliLiveShiftPlayerMap.get(playerId)) {
                    mPlayer = mFlutterAliLiveShiftPlayerMap.get(playerId);
                }

                if (null != flutterAliPlayerView && null != mPlayer) {
                    // 遍历所有 view，清除旧 view 的 mPlayer 引用
                    // 防止旧 view 销毁时 onSurfaceTextureDestroyed 中的 setSurface(null)
                    // 影响已绑定到新 view 的播放器
                    for (FlutterAliPlayerView oldView : mFlutterAliPlayerViewMap.values()) {
                        if (oldView != flutterAliPlayerView) {
                            oldView.clearPlayer();
                        }
                    }
                    flutterAliPlayerView.setPlayer(mPlayer.getAliPlayer());
                }
            }
            break;
            case "setUseHttp2":
                Boolean enableUseHttp2 = call.arguments();
                AliPlayerGlobalSettings.setUseHttp2(enableUseHttp2);
                break;
            case "enableHttpDns":
                Boolean enableHttpDns = call.arguments();
                AliPlayerGlobalSettings.enableHttpDns(enableHttpDns);
                break;
            case "setDNSResolve":
                Map<String, String> dnsResolveMap = call.arguments();
                if (dnsResolveMap != null) {
                    String dnsResolveHost = dnsResolveMap.get("host");
                    String dnsResolveIP = dnsResolveMap.get("ip");
                    AliPlayerGlobalSettings.setDNSResolve(dnsResolveHost, dnsResolveIP);
                }
                result.success(null);
                break;
            case "enableNetworkBalance":
                Boolean enableNetworkBalance = call.arguments();
                AliPlayerGlobalSettings.enableNetworkBalance(enableNetworkBalance);
                result.success(null);
                break;
            case "enableLocalCache":
                Map<String, Object> localCacheMap = call.arguments();
                if (localCacheMap != null) {
                    Boolean enable = (Boolean) localCacheMap.get("enable");
                    String maxBufferMemoryKB = (String) localCacheMap.get("maxBufferMemoryKB");
                    String localCacheDir = (String) localCacheMap.get("localCacheDir");
                    AliPlayerGlobalSettings.enableLocalCache(enable, Integer.valueOf(maxBufferMemoryKB), localCacheDir);
                }
                break;
            case "setCacheFileClearConfig":
                Map<String, Object> cacheFileClearConfig = call.arguments();
                if (cacheFileClearConfig != null) {
                    String expireMin = (String) cacheFileClearConfig.get("expireMin");
                    String maxCapacityMB = (String) cacheFileClearConfig.get("maxCapacityMB");
                    String freeStorageMB = (String) cacheFileClearConfig.get("freeStorageMB");
                    AliPlayerGlobalSettings.setCacheFileClearConfig(Long.parseLong(expireMin), Long.parseLong(maxCapacityMB), Long.parseLong(freeStorageMB));
                }
                break;
            case "clearCaches":
                AliPlayerGlobalSettings.clearCaches();
                break;
            case "isFeatureSupport":
                result.success(AliPlayerFactory.isFeatureSupport(AliPlayerFactory.SupportFeatureType.FeatureDolbyAudio));
                break;
            case "setIPResolveType":
                String setIPResolveTypeStr = call.arguments() == null ? "" : (String) call.arguments();
                switch (setIPResolveTypeStr) {
                    case "v4":
                        AliPlayerGlobalSettings.setIPResolveType(IPlayer.IPResolveType.IpResolveV4);
                        break;
                    case "v6":
                        AliPlayerGlobalSettings.setIPResolveType(IPlayer.IPResolveType.IpResolveV6);
                        break;
                    default:
                        AliPlayerGlobalSettings.setIPResolveType(IPlayer.IPResolveType.IpResolveWhatEver);
                        break;
                }
                break;
            case "forceAudioRendingFormat":
                Map<String, Object> forceAudioRendingFormat = call.arguments();
                Boolean force = Boolean.getBoolean((String) forceAudioRendingFormat.get("force"));
                String fmt = (String) forceAudioRendingFormat.get("fmt");
                Integer channels = Integer.valueOf((String) forceAudioRendingFormat.get("channels"));
                Integer sample_rate = Integer.valueOf((String) forceAudioRendingFormat.get("sample_rate"));
                AliPlayerGlobalSettings.forceAudioRendingFormat(force, fmt, channels, sample_rate);
                break;
            case "createVidPlayerConfigGenerator":
                mVidPlayerConfigGen = new VidPlayerConfigGen();
                result.success(null);
                break;
            case "setPreviewTime":
                String setPreviewTime = call.arguments();
                if (mVidPlayerConfigGen != null && !TextUtils.isEmpty(setPreviewTime)) {
                    mVidPlayerConfigGen.setPreviewTime(Integer.parseInt(setPreviewTime));
                }
                result.success(null);
                break;
            case "setHlsUriToken":
                String setHlsUriToken = call.arguments();
                if (mVidPlayerConfigGen != null) {
                    mVidPlayerConfigGen.setMtsHlsUriToken(setHlsUriToken);
                }
                result.success(null);
                break;
            case "addVidPlayerConfigByStringValue":

            case "addVidPlayerConfigByIntValue":
                Map<String, String> addVidPlayerConfigByStringValue = (Map<String, String>) call.arguments;
                if (mVidPlayerConfigGen != null) {
                    for (String s : addVidPlayerConfigByStringValue.keySet()) {
                        mVidPlayerConfigGen.addPlayerConfig(s, addVidPlayerConfigByStringValue.get(s));
                    }
                }
                result.success(null);
                break;
            case "setEncryptType":
                int encryptType = (int) call.arguments;
                if (mVidPlayerConfigGen != null) {
                    mVidPlayerConfigGen.setEncryptType(VidPlayerConfigGen.EncryptType.values()[encryptType]);
                }
                result.success(null);
                break;
            case "generatePlayerConfig":
                String generatePlayerConfig = mVidPlayerConfigGen.genConfig();
                result.success(generatePlayerConfig);
                break;
            default:
                String otherPlayerId = call.argument("playerId");
                if (mFlutterAliPlayerMap.containsKey(otherPlayerId)) {
                    String playerId = call.argument("playerId");
                    FlutterAliPlayer mCurrentFlutterAliPlayer = mFlutterAliPlayerMap.get(playerId);
                    if (call.method.equals("destroy")) {
                        mFlutterAliPlayerMap.remove(playerId);
                    }
                    if (call.method.equals("releaseAsync")) {
                        mFlutterAliPlayerMap.remove(playerId);
                    }

                    if (mCurrentFlutterAliPlayer != null) {
                        mCurrentFlutterAliPlayer.onMethodCall(call, result);
                    }
                } else if (mFlutterAliLiveShiftPlayerMap.containsKey(otherPlayerId)) {
//                    String playerId = call.argument("playerId");
                    FlutterAliLiveShiftPlayer mCurrentFlutterAliLiveShiftPlayer = mFlutterAliLiveShiftPlayerMap.get(otherPlayerId);
                    if (call.method.equals("destroy")) {
                        mFlutterAliLiveShiftPlayerMap.remove(otherPlayerId);
                    }
                    if (call.method.equals("releaseAsync")) {
                        mFlutterAliLiveShiftPlayerMap.remove(otherPlayerId);
                    }
                    if (mCurrentFlutterAliLiveShiftPlayer != null) {
                        mCurrentFlutterAliLiveShiftPlayer.onMethodCall(call, result);
                    }
                } else if (mFlutterAliListPlayerMap.containsKey(otherPlayerId)) {
                    FlutterAliListPlayer mCurrentAliListPlayer = mFlutterAliListPlayerMap.get(otherPlayerId);
                    if (call.method.equals("destroy")) {
                        mFlutterAliListPlayerMap.remove(otherPlayerId);
                    }
                    if (call.method.equals("releaseAsync")) {
                        mFlutterAliListPlayerMap.remove(otherPlayerId);
                    }
                    if (mCurrentAliListPlayer != null) {
                        mCurrentAliListPlayer.onMethodCall(call, result);
                    }
                }
        }
    }

    private Integer getLogLevel() {
        return Logger.getInstance(flutterPluginBinding.getApplicationContext()).getLogLevel().getValue();
    }

    private String createDeviceInfo() {
        AliPlayerFactory.DeviceInfo deviceInfo = new AliPlayerFactory.DeviceInfo();
        deviceInfo.model = Build.MODEL;
        return deviceInfo.model;
    }

    private void addBlackDevice(String blackType, String modelInfo) {
        AliPlayerFactory.DeviceInfo deviceInfo = new AliPlayerFactory.DeviceInfo();
        deviceInfo.model = modelInfo;
        AliPlayerFactory.BlackType aliPlayerBlackType;
        if (!TextUtils.isEmpty(blackType) && blackType.equals("HW_Decode_H264")) {
            aliPlayerBlackType = AliPlayerFactory.BlackType.HW_Decode_H264;
        } else {
            aliPlayerBlackType = AliPlayerFactory.BlackType.HW_Decode_HEVC;
        }
        AliPlayerFactory.addBlackDevice(aliPlayerBlackType, deviceInfo);
    }

    private void enableConsoleLog(Boolean enableLog) {
        Logger.getInstance(flutterPluginBinding.getApplicationContext()).enableConsoleLog(enableLog);
    }

    private void setLogLevel(int level) {
        Logger.LogLevel mLogLevel;
        if (level == Logger.LogLevel.AF_LOG_LEVEL_NONE.getValue()) {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_NONE;
        } else if (level == Logger.LogLevel.AF_LOG_LEVEL_FATAL.getValue()) {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_FATAL;
        } else if (level == Logger.LogLevel.AF_LOG_LEVEL_ERROR.getValue()) {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_ERROR;
        } else if (level == Logger.LogLevel.AF_LOG_LEVEL_WARNING.getValue()) {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_WARNING;
        } else if (level == Logger.LogLevel.AF_LOG_LEVEL_INFO.getValue()) {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_INFO;
        } else if (level == Logger.LogLevel.AF_LOG_LEVEL_DEBUG.getValue()) {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_DEBUG;
        } else if (level == Logger.LogLevel.AF_LOG_LEVEL_TRACE.getValue()) {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_TRACE;
        } else {
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_NONE;
        }
        Logger.getInstance(flutterPluginBinding.getApplicationContext()).setLogLevel(mLogLevel);
    }

    private void setOnLogCallback(Boolean enableLog) {
        mOnLogCallback = enableLog ? new Logger.OnLogCallback() {
            @Override
            public void onLog(Logger.LogLevel logLevel, String strlog) {
                Map<String, String> map = new HashMap<>();
                map.put("method", "AliPlayer_LogCallBackInfo");
                map.put("logLevel", logLevel.getValue() + "");
                map.put("strLog", strlog);
                mEventSink.success(map);
            }
        } : null;
        Logger.getInstance(flutterPluginBinding.getApplicationContext()).setLogCallback(mOnLogCallback);
    }

    /**
     * 设置监听
     */
    private void initListener(FlutterPlayerBase flutterPlayerBase) {
        flutterPlayerBase.setOnFlutterListener(new FlutterAliPlayerListener() {
            @Override
            public void onPrepared(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackReady(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubTrackReady(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onCompletion(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onRenderingStart(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onVideoSizeChanged(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onVideoRendered(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSnapShot(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackChangedSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackChangedFail(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSeekComplete(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSeiData(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingBegin(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingProgress(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingEnd(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onStateChanged(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleExtAdded(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleShow(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleHide(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleHeader(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onInfo(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onError(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailPrepareSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailPrepareFail(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailGetSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailGetFail(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTimeShiftUpdater(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSeekLiveCompletion(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onReportEventListener(final Map<String, Object> map) {
                sMainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        mEventSink.success(map);
                    }
                });
            }

            @Override
            public int onChooseTrackIndex(Map<String, Object> map) {
                mEventSink.success(map);
                return 0;
            }

            @Override
            public void onStreamSwitchedSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onStreamSwitchedFail(Map<String, Object> map) {
                mEventSink.success(map);
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        destroyPluginChannel(binding);
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        FlutterAliPlayerView flutterAliPlayerView = new FlutterAliPlayerView(context, viewId, args);
        flutterAliPlayerView.setFlutterAliPlayerViewListener(this);
        mFlutterAliPlayerViewMap.put(viewId, flutterAliPlayerView);
        return flutterAliPlayerView;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.mEventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
    }

    @Override
    public void onDispose(int viewId) {
        mFlutterAliPlayerViewMap.remove(viewId);
        AliChannelPool.getInstance().clear();
    }


    /**
     * 加载 Flutter 工程 Asset 目录下的图片
     *
     * @param assetPath 资源路径
     * @return 返回 BitmapDrawable 图片
     */
    private Drawable loadFlutterAsset(String assetPath) {
        InputStream inputStream = null;
        try {
            // 获取 Flutter 的 AssetManager
            String filePathKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath);

            AssetManager manager = mContext.getAssets();
            // 打开 asset 流
            inputStream = manager.open(filePathKey);
            Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
            inputStream.close();
            inputStream = null;
            return new BitmapDrawable(mContext.getResources(), bitmap);
        } catch (Exception e) {
            Log.e(TAG, "the File is open Error :" + Log.getStackTraceString(e));
        } finally {
            if (inputStream != null) {
                try {
                    inputStream.close();
                } catch (Exception e) {
                    // 忽略关闭异常
                }
            }
        }
        return null;
    }


    /**
     * 检查悬浮窗权限
     *
     * @return true/false
     */
    private boolean checkFloatWindowPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.canDrawOverlays(mContext);
        } else {
            return true;// Android < 6.0 默认有权限
        }
    }

    /**
     * 请求悬浮窗权限
     *
     * @param activity 使用当前可用的Activity
     */
    private void requestFloatWindowPermission(Activity activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + activity.getApplication().getApplicationContext().getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activity.startActivity(intent);
        }
    }


    /**
     * 根据变量是否加载 license库
     */
    private void checkAvailableRts() {
        boolean isRts = mContext.getResources().getBoolean(R.bool.use_aio_framework);
        if (!isRts) {
            System.loadLibrary("RtsSDK");
            System.loadLibrary("cicada_plugin_artcSource");
        }
    }


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        mBindActivity = binding.getActivity();
        mAliPlayerGlobalSettings.setmBindActivity(mBindActivity);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.mBindActivity = null;
        mAliPlayerGlobalSettings.setmBindActivity(null);
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.mBindActivity = binding.getActivity();
        mAliPlayerGlobalSettings.setmBindActivity(mBindActivity);
    }

    @Override
    public void onDetachedFromActivity() {
        this.mBindActivity = null;
        mAliPlayerGlobalSettings.setmBindActivity(null);
    }
}
