package com.alibaba.fplayer.flutter_aliplayer;

import androidx.annotation.NonNull;

import com.alibaba.fplayer.flutter_aliplayer.common.AliPlayerBaseModule;
import com.aliyun.loader.MediaLoaderV2;
import com.aliyun.loader.OnPreloadListener;
import com.aliyun.loader.PreloadTask;
import com.aliyun.player.VidPlayerConfigGen;
import com.aliyun.player.bean.ErrorInfo;
import com.aliyun.player.nativeclass.PreloadConfig;
import com.aliyun.player.source.UrlSource;
import com.aliyun.player.source.VidAuth;
import com.aliyun.player.source.VidSourceBase;
import com.aliyun.player.source.VidSts;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterAliMediaLoaderV2 extends AliPlayerBaseModule {

    // 预加载V2
    private MediaLoaderV2 mediaLoaderV2;

    // 预加载设置
    private PreloadConfig preloadConfig;

    // 预加载监听
    private OnPreloadListener mOnPreloadListener;


    // 初始化必要参数
    private void initParams() {
        this.mediaLoaderV2 = MediaLoaderV2.getInstance(); // 预加载器
        this.preloadConfig = new PreloadConfig(); // 预加载设置

        // OnPreloadListener 接口实现
        this.mOnPreloadListener = new OnPreloadListener() {
            /**
             * 当预加载任务发生错误时调用此方法
             * 用于处理预加载过程中出现的异常情况
             *
             * @param taskId    任务ID，唯一标识一个预加载任务
             * @param urlOrVid  视频源地址或VID标识
             * @param errorInfo 错误信息对象，包含错误码和错误描述
             */
            @Override
            public void onError(String taskId, String urlOrVid, ErrorInfo errorInfo) {
                Map<String, String> resultMap = new HashMap<>();
                resultMap.put("method", "onError");
                resultMap.put("taskId", taskId);
                resultMap.put("urlOrVid", urlOrVid);
                resultMap.put("errorCode", String.valueOf(errorInfo.getCode().getValue()));

                if (null != errorInfo.getMsg() && !errorInfo.getMsg().isEmpty()) {
                    resultMap.put("errorMsg", errorInfo.getMsg());
                }

                if (null != errorInfo.getExtra() && !errorInfo.getExtra().isEmpty()) {
                    resultMap.put("errorExtra", errorInfo.getExtra());
                }

                sendSuccessEvent(resultMap);
            }

            /**
             * 当预加载任务完成时调用此方法
             * 用于处理预加载成功完成后的回调
             *
             * @param taskId   任务ID，唯一标识一个预加载任务
             * @param urlOrVid 视频源地址或VID标识
             */
            @Override
            public void onCompleted(String taskId, String urlOrVid) {
                Map<String, String> resultMap = new HashMap<>();
                resultMap.put("method", "onCompleted");
                resultMap.put("taskId", taskId);
                resultMap.put("urlOrVid", urlOrVid);

                sendSuccessEvent(resultMap);
            }

            /**
             * 当预加载任务被取消时调用此方法
             * 用于处理用户主动取消预加载的情况
             *
             * @param taskId   任务ID，唯一标识一个预加载任务
             * @param urlOrVid 视频源地址或VID标识
             */
            @Override
            public void onCanceled(String taskId, String urlOrVid) {
                Map<String, String> resultMap = new HashMap<>();
                resultMap.put("method", "onCanceled");
                resultMap.put("taskId", taskId);
                resultMap.put("urlOrVid", urlOrVid);

                sendSuccessEvent(resultMap);
            }
        };
    }

    // 销毁必要参数
    private void destroyParams() {
        mediaLoaderV2 = null;
        preloadConfig = null;
        mOnPreloadListener = null;
    }

    /**
     * 当 Flutter 插件被附加到 Flutter 引擎模块时调用
     *
     * <p>此方法在插件生命周期的初始化阶段执行，通常用于：
     * <ul>
     *   <li>获取 FlutterPluginBinding 对象，用于访问上下文和二进制消息处理器</li>
     *   <li>初始化原生端的 MethodChannel 和 EventChannel</li>
     *   <li>设置通道的 MethodCallHandler 和 StreamHandler</li>
     *   <li>初始化插件所需的其他资源（如传感器、数据库连接等）</li>
     * </ul>
     *
     * <p><strong>注意：</strong>此方法只会被调用一次，除非插件被分离后再重新附加。
     *
     * @param binding {@link FlutterPlugin.FlutterPluginBinding} 对象，
     *                提供对 Android 上下文、FlutterEngine 以及二进制消息通道的访问
     */
    @Override
    public void onAttachedToModule(FlutterPlugin.FlutterPluginBinding binding) {
        super.onAttachedToModule(binding);
        initParams(); // 初始化插件参数和资源
    }

    /**
     * 当 Flutter 插件从 Flutter 引擎模块分离时调用
     *
     * <p>此方法在插件生命周期的销毁阶段执行，通常用于：
     * <ul>
     *   <li>清理和释放插件占用的系统资源</li>
     *   <li>取消正在进行的异步操作或监听器</li>
     *   <li>断开与硬件设备的连接</li>
     *   <li>移除 MethodChannel 和 EventChannel 的处理器</li>
     *   <li>防止内存泄漏和资源浪费</li>
     * </ul>
     *
     * <p><strong>重要：</strong>在此方法中必须确保所有资源都被正确释放，
     * 否则可能导致内存泄漏或应用崩溃。
     *
     * <p><strong>调用时机：</strong>通常在 FlutterActivity 销毁、FlutterEngine 被释放
     * 或插件被显式卸载时调用。
     *
     * @param binding {@link FlutterPlugin.FlutterPluginBinding} 对象，
     *                与 onAttachedToModule 中的参数相同，可用于访问相关上下文信息
     */
    @Override
    public void onDetachedFromModule(FlutterPlugin.FlutterPluginBinding binding) {
        super.onDetachedFromModule(binding);
        destroyParams(); // 销毁和清理插件资源
    }


    // =============================================================================================
    // == EventChannel.StreamHandler 接口实现
    // =============================================================================================

    /**
     * 当Flutter层开始监听事件流时调用此方法
     * 用于建立事件发送通道，接收来自原生层的事件通知
     *
     * @param arguments 传递的参数对象，可包含配置信息
     * @param events    事件发送器，用于向Flutter层发送事件数据
     */
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.mEventSink = events;
    }

    /**
     * 当Flutter层取消事件监听时调用此方法
     * 用于清理事件监听相关的资源和回调
     *
     * @param arguments 传递的参数对象，与onListen方法中的参数对应
     */
    @Override
    public void onCancel(Object arguments) {
        this.mEventSink = null;
    }

    @Override
    protected String buildMethodChannel() {
        return "plugins.flutter_aliplayer_loader_v2";
    }

    @Override
    protected String buildEventChannel() {
        return "flutter_aliplayer_loader_v2_event";
    }


    // =============================================================================================
    // == MethodChannel.MethodCallHandler 接口实现
    // =============================================================================================

    /**
     * 处理来自Flutter层的方法调用请求
     * 根据不同的方法名执行相应的业务逻辑
     *
     * @param call   方法调用对象，包含方法名和参数
     * @param result 方法调用结果回调，用于返回执行结果给Flutter层
     */
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        // 当前实现为空，需根据具体业务需求实现方法处理逻辑
        switch (call.method) {
            case "addTask": {
                addTask(call, result);
            }
            break;
            case "pauseTask": {
                String taskId = call.argument("taskId");
                mediaLoaderV2.pauseTask(taskId);
            }
            break;
            case "resumeTask": {
                String taskId = call.argument("taskId");
                mediaLoaderV2.resumeTask(taskId);
            }
            break;
            case "cancelTask": {
                String taskId = call.argument("taskId");
                mediaLoaderV2.cancelTask(taskId);
            }
            break;
            case "getPreloadConfig": {
                Map<String, Object> configMap = new HashMap<>();
                configMap.put("duration", preloadConfig.getDuration());
                configMap.put("defaultBandWidth", preloadConfig.getDefaultBandWidth());
                configMap.put("defaultQuality", preloadConfig.getDefaultQuality());
                configMap.put("defaultResolution", preloadConfig.getDefaultResolution());
                result.success(configMap);
            }
            break;
            case "setPreloadConfig": {
                Map<String, Object> map = call.arguments();
                if (null != map) {
                    if (map.containsKey("duration")) {
                        Object durationObj = map.get("duration");
                        if (durationObj instanceof Integer) {
                            int duration = (int) durationObj;
                            preloadConfig.setDuration(duration);
                        }
                    }

                    if (map.containsKey("defaultBandWidth")) {
                        Object defaultBandWidthObj = map.get("defaultBandWidth");
                        if (defaultBandWidthObj instanceof Integer) {
                            int defaultBandWidth = (int) defaultBandWidthObj;
                            preloadConfig.setDefaultBandWidth(defaultBandWidth);
                        }
                    }

                    if (map.containsKey("defaultResolution")) {
                        Object defaultResolutionObj = map.get("defaultResolution");
                        if (defaultResolutionObj instanceof Integer) {
                            int defaultResolution = (int) defaultResolutionObj;
                            preloadConfig.setDefaultResolution(defaultResolution);
                        }
                    }

                    if (map.containsKey("defaultQuality")) {
                        Object defaultQualityObj = map.get("defaultQuality");
                        if (defaultQualityObj instanceof String) {
                            String defaultQuality = (String) defaultQualityObj;
                            preloadConfig.setDefaultQuality(defaultQuality);
                        }
                    }

                    result.success(null);
                }
            }
            break;
            case "resetPreloadConfig": {
                preloadConfig = new PreloadConfig();
                result.success(null);
            }
            break;
            default:
                break;
        }
    }

    /**
     * 处理来自 Flutter 端的“添加预加载任务”方法调用
     *
     * <p>该方法从 MethodCall 中解析视频预加载参数，根据视频类型构建对应的 {@link PreloadTask}，
     * 并通过 {@link #mediaLoaderV2} 提交任务，最后将生成的任务 ID 返回给 Flutter 端。
     *
     * @param call   包含方法名和参数的 {@link MethodCall} 对象，预期参数为包含视频配置的 Map
     * @param result 用于向 Flutter 端返回结果的回调对象
     */
    private void addTask(MethodCall call, MethodChannel.Result result) {
        // 从 MethodCall 中获取参数 Map（由 Dart 端传递）
        Map<String, Object> addTaskMap = call.arguments();

        // 安全检查：确保参数不为空且非空 Map
        if (null != addTaskMap && !addTaskMap.isEmpty()) {
            // 获取视频类型标识（0: UrlSource, 1: VidAuth, 2: VidSts）
            Object obj = addTaskMap.get("videoType");
            int videoType = (obj instanceof Integer) ? (Integer) obj : 0;

            // 根据视频类型和参数构建预加载任务
            PreloadTask task = buildPreloadTask(videoType, addTaskMap);

            // 将任务提交给媒体预加载器，并注册监听器
            String taskId = mediaLoaderV2.addTask(task, mOnPreloadListener);

            // 成功返回任务 ID 给 Flutter 端（用于后续任务管理）
            result.success(taskId);
        }
        // 注意：如果参数为空，当前实现会静默忽略。可根据需求改为返回错误
    }

    /**
     * 根据视频类型和配置数据构建 {@link PreloadTask} 实例
     *
     * <p>支持三种视频源类型：
     * <ul>
     *   <li><b>0 - UrlSource</b>：直接通过视频 URL 播放</li>
     *   <li><b>1 - VidAuth</b>：通过视频 ID + 播放凭证（PlayAuth）播放（阿里云标准方案）</li>
     *   <li><b>2 - VidSts</b>：通过视频 ID + STS 临时凭证播放（适用于需要细粒度权限控制的场景）</li>
     * </ul>
     *
     * <p><strong>注意：</strong>所有视频源类型均使用统一的预加载配置 {@link #buildPreloadConfig()}。
     *
     * @param videoType 视频源类型标识（0/1/2）
     * @param dataMap   包含具体视频参数的键值对（如 vid、playAuth、url 等）
     * @return 构建完成的 {@link PreloadTask} 实例，若类型无效则返回 null
     */
    private PreloadTask buildPreloadTask(int videoType, Map<String, Object> dataMap) {
        PreloadTask preloadTask = null;

        switch (videoType) {
            case 0: {
                // ===== UrlSource 类型：直接通过 HTTP/HTTPS URL 播放 =====
                String videoUrl = (String) dataMap.get("videoUrl");
                UrlSource urlSource = new UrlSource();
                urlSource.setUri(videoUrl);
                preloadTask = new PreloadTask(urlSource, buildPreloadConfig());
                break; // 建议显式添加 break 避免 fall-through（虽然此处无害）
            }
            case 1: {
                // ===== VidAuth 类型：阿里云视频点播标准鉴权方式 =====
                String playVideoId = (String) dataMap.get("vid");
                String playAuth = (String) dataMap.get("playAuth");
                String region = (String) dataMap.get("region");

                VidAuth vidAuth = new VidAuth();
                vidAuth.setVid(playVideoId);
                vidAuth.setPlayAuth(playAuth);

                // 区域参数可选，仅在非空时设置
                if (null != region && !region.isEmpty()) {
                    vidAuth.setRegion(region);
                }

                setSourceConfig(dataMap, vidAuth);


                preloadTask = new PreloadTask(vidAuth, buildPreloadConfig());
                break;
            }
            case 2: {
                // ===== VidSts 类型：基于 STS 临时安全令牌的鉴权方式 =====
                String playVideoId = (String) dataMap.get("vid");
                String accessKeyId = (String) dataMap.get("accessKeyId");
                String accessKeySecret = (String) dataMap.get("accessKeySecret");
                String securityToken = (String) dataMap.get("securityToken");
                String region = (String) dataMap.get("region");

                VidSts vidSts = new VidSts();
                vidSts.setVid(playVideoId);
                vidSts.setAccessKeyId(accessKeyId);
                vidSts.setAccessKeySecret(accessKeySecret);
                vidSts.setSecurityToken(securityToken);

                setSourceConfig(dataMap, vidSts);
                // 区域参数可选，仅在非空时设置
                if (null != region && !region.isEmpty()) {
                    vidSts.setRegion(region);
                }


                preloadTask = new PreloadTask(vidSts, buildPreloadConfig());
                break;
            }
        }
        return preloadTask;
    }


    private void setSourceConfig(Map<String, Object> dataMap, VidSourceBase sourceBase) {
        if (dataMap.containsKey("config")) {
            Map<String, Object> configMap = (Map<String, Object>) dataMap.get("config");
            if (null != configMap && !configMap.isEmpty()) {
                Object typeObj = configMap.get("type");

                if (typeObj instanceof Number) {
                    int type = ((Number) typeObj).intValue();
                    VidPlayerConfigGen configGen = null;

                    switch (type) {
                        case 1: {
                            // 私有加密
                            configGen = new VidPlayerConfigGen();
                            configGen.setEncryptType(VidPlayerConfigGen.EncryptType.AliyunVodEncryption);
                            break;
                        }
                        case 2: {
                            configGen = new VidPlayerConfigGen();
                            configGen.setEncryptType(VidPlayerConfigGen.EncryptType.HLSEncryption);

                            if (configMap.containsKey("hlsUriToken")) {
                                String hlsUrlToken = (String) configMap.get("hlsUriToken");
                                configGen.setMtsHlsUriToken(hlsUrlToken);
                            }
                            break;
                        }
                        default:
                            break;
                    }

                    if (null != configGen && null != sourceBase) {
                        sourceBase.setPlayConfig(configGen);
                    }
                }

            }
        }
    }

    /**
     * 获取预加载任务的通用配置
     *
     * <p>返回预定义的 {@link PreloadConfig} 实例，该配置适用于所有类型的预加载任务。
     * 配置内容可能包括：缓存策略、并发数、超时时间等。
     *
     * <p><strong>设计说明：</strong>采用单一配置实例，确保所有预加载任务行为一致。
     * 如需差异化配置，可考虑将配置参数也通过 {@code dataMap} 传入。
     *
     * @return 全局预加载配置对象
     */
    private PreloadConfig buildPreloadConfig() {
        return preloadConfig; // preloadConfig 应在类初始化时创建并复用
    }


}
