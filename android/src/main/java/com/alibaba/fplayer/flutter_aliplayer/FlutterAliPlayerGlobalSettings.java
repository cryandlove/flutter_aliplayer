package com.alibaba.fplayer.flutter_aliplayer;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.provider.Settings;
import android.util.Log;

import androidx.annotation.NonNull;

import com.aliyun.aio.aio_env.AlivcEnv;
import com.aliyun.common.AlivcBase;
import com.aliyun.player.AliPlayerGlobalSettings;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * @author junhuiYe
 * @date 2024/11/19
 * @brief
 */
@SuppressLint("LongLogTag")
public class FlutterAliPlayerGlobalSettings implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private MethodChannel mMethodChannel;
    private final String TAG = "FlutterAliPlayerGlobalSettings";
    private volatile FlutterInvokeCallback flutterInvokeCallback;

    private Activity mBindActivity;

    public FlutterAliPlayerGlobalSettings(Context context, FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        flutterInvokeCallback = new FlutterInvokeCallback(context, flutterPluginBinding);
        this.mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "plugins.flutter_global_setting");
        this.mMethodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "setGlobalEnvironment":
                setGlobalEnvironment((Integer) call.arguments());
                result.success(null);
                break;
            case "setOption":
                Map<String, Object> args = call.arguments();
                setOption((Integer) args.get("opt1"), args.get("opt2"));
                result.success(null);
                break;
            case "disableCrashUpload":
                AliPlayerGlobalSettings.disableCrashUpload((Boolean) call.arguments());
                break;
            case "enableEnhancedHttpDns":
                AliPlayerGlobalSettings.enableEnhancedHttpDns((Boolean) call.arguments());
                break;
            case "setCacheUrlHashCallback":
                AliPlayerGlobalSettings.setCacheUrlHashCallback(url -> {
                    FlutterInvokeCallback callback = flutterInvokeCallback;
                    if (callback != null) {
                        String newUrl = (String) callback.invokeOneParameterFlutterCallback(url, "getUrlHashCallback");
                        return newUrl != null ? newUrl : url;
                    }
                    return url;
                });
                break;
            case "setNetworkCallback":
                AliPlayerGlobalSettings.setNetworkCallback((s, byteBuffer, l, byteBuffer1) -> {
                    FlutterInvokeCallback callback = flutterInvokeCallback;
                    if (callback != null) {
                        return (Boolean) callback.invokeFourParameterFlutterCallback(s, byteBuffer, l, byteBuffer1, "onNetworkDataProcess");
                    }
                    return false;
                });
                break;
            case "setAdaptiveDecoderGetBackupURLCallback":
                AliPlayerGlobalSettings.setAdaptiveDecoderGetBackupURLCallback((oriBizScene, oriCodecType, original_url) -> {
                    FlutterInvokeCallback callback = flutterInvokeCallback;
                    if (callback != null) {
                        return (String) callback.invokeThreeParameterFlutterCallback(oriBizScene, oriCodecType, original_url, "getBackupUrlCallback");
                    }
                    return null;
                });
                break;
            case "setSystemBrightness": {
                Log.e("API", "[setSystemBrightness]" + call.arguments);
                // 设置系统亮度
                Double brightness = call.argument("brightness");
                if (null != brightness) {
                    setSystemBrightness(brightness);
                }
                result.success(null);
            }
            break;
            case "getSystemBrightness": {
                // 获取系统系统
                result.success(getSystemBrightness());
            }
            break;
            default:
                break;
        }
    }

    private void setOption(int opt1, Object opt2) {
        if (opt2 instanceof Integer) {
            AliPlayerGlobalSettings.setOption(opt1, (Integer) opt2);
        } else if (opt2 instanceof String) {
            AliPlayerGlobalSettings.setOption(opt1, (String) opt2);
        }
    }

    private void setGlobalEnvironment(int GlobalEnv) {
        switch (GlobalEnv) {
            case 1:
                AlivcBase.getEnvironmentManager().setGlobalEnvironment(AlivcEnv.GlobalEnv.ENV_CN);
                break;
            case 2:
                AlivcBase.getEnvironmentManager().setGlobalEnvironment(AlivcEnv.GlobalEnv.ENV_SEA);
                break;
            case 3:
                AlivcBase.getEnvironmentManager().setGlobalEnvironment(AlivcEnv.GlobalEnv.ENV_GLOBAL_OVERSEA);
                break;
            default:
                AlivcBase.getEnvironmentManager().setGlobalEnvironment(AlivcEnv.GlobalEnv.ENV_DEFAULT);
                break;
        }
    }


    /**
     * 设置应用内亮度
     *
     * @param brightness 范围 [0.0, 1.0]
     */
    private void setSystemBrightness(double brightness) {
        if (mBindActivity == null) {
            return;
        }

        // 1. 钳位处理：确保值在 0.0 到 1.0 之间
        // Math.max(0.0, Math.min(1.0, brightness)) 等价于 clamp
        double clampedBrightness = Math.max(0.0, Math.min(1.0, brightness));

        // 2. 转换为 float 并设置
        android.view.WindowManager.LayoutParams layout = mBindActivity.getWindow().getAttributes();
        layout.screenBrightness = (float) clampedBrightness;

        // 3. 应用更改
        mBindActivity.getWindow().setAttributes(layout);
    }

    /**
     * 获取当前应用内亮度
     *
     * @return 范围 [0.0, 1.0]
     */
    private float getSystemBrightness() {
        if (mBindActivity != null) {
            float brightness = mBindActivity.getWindow().getAttributes().screenBrightness;

            // Android 特性：如果值为 -1，表示跟随系统默认亮度
            if (brightness == -1.0f) {
                try {
                    // 读取系统全局亮度 (0-255)
                    int systemBrightness = android.provider.Settings.System.getInt(mBindActivity.getContentResolver(), android.provider.Settings.System.SCREEN_BRIGHTNESS);
                    // 转换回 0.0 - 1.0
                    return systemBrightness / 255.0f;
                } catch (Exception e) {
                    e.printStackTrace();
                    return 0.5f; // 异常时返回默认中间值
                }
            }

            // 如果已经设置过应用内亮度，直接返回 (0.0 - 1.0)
            // 防止因浮点数精度问题导致略微超出，再次钳位
            return Math.max(0.0f, Math.min(1.0f, brightness));
        }
        return 0.5f;
    }

    public void destroy() {
        if (mMethodChannel != null) {
            mMethodChannel.setMethodCallHandler(null);
            mMethodChannel = null;
        }
        flutterInvokeCallback = null;
        mBindActivity = null;
    }

    public void setmBindActivity(Activity mBindActivity) {
        this.mBindActivity = mBindActivity;
    }
}
