package com.alibaba.fplayer.flutter_aliplayer;

import androidx.annotation.NonNull;

import com.alibaba.fplayer.flutter_aliplayer.common.AliPlayerBaseModule;
import com.aliyun.loader.MediaLoader;
import com.aliyun.player.bean.ErrorInfo;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterAliMediaLoader extends AliPlayerBaseModule {

    private MediaLoader mMediaLoader;

    private MediaLoader.OnLoadStatusListener mOnLoadStatusListener;


    private void initParam() {
        mMediaLoader = MediaLoader.getInstance();
        if (null == mOnLoadStatusListener) {
            mOnLoadStatusListener = new MediaLoader.OnLoadStatusListener() {
                @Override
                public void onError(String url, int code, String msg) {
                    Map<String, String> resultMap = new HashMap<>();
                    resultMap.put("method", "onError");
                    resultMap.put("url", url);
                    resultMap.put("code", String.valueOf(code));
                    resultMap.put("msg", msg);
                    sendSuccessEvent(resultMap);
                }

                @Override
                public void onCompleted(String url) {
                    Map<String, String> resultMap = new HashMap<>();
                    resultMap.put("method", "onCompleted");
                    resultMap.put("url", url);
                    sendSuccessEvent(resultMap);
                }

                @Override
                public void onCanceled(String url) {
                    Map<String, String> resultMap = new HashMap<>();
                    resultMap.put("method", "onCanceled");
                    resultMap.put("url", url);
                    sendSuccessEvent(resultMap);
                }

                @Override
                public void onErrorV2(String url, ErrorInfo errorInfo) {
                    Map<String, String> resultMap = new HashMap<>();
                    resultMap.put("method", "onErrorV2");
                    resultMap.put("url", url);
                    resultMap.put("code", errorInfo.getCode().name());
                    resultMap.put("msg", errorInfo.getMsg());
                    sendSuccessEvent(resultMap);
                }
            };
        }
        mMediaLoader.setOnLoadStatusListener(mOnLoadStatusListener);
    }

    private void destroyParam() {
        mMediaLoader = null;
        mOnLoadStatusListener = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "load":
                Map<String, String> loadMap = call.arguments();
                if (null != loadMap) {
                    String url = loadMap.get("url");
                    String duration = loadMap.get("duration");
                    if (loadMap.containsKey("bandWidth")) {
                        int bandWidth = Integer.parseInt(loadMap.get("bandWidth"));
                        mMediaLoader.load(url, Long.parseLong(duration), bandWidth);
                    } else {
                        mMediaLoader.load(url, Long.parseLong(duration));
                    }
                }
                break;
            case "resume":
                String resumeUrl = call.arguments();
                mMediaLoader.resume(resumeUrl);
                break;
            case "pause":
                String pauseUrl = call.arguments();
                mMediaLoader.pause(pauseUrl);
                break;
            case "cancel":
                String cancelUrl = call.arguments();
                mMediaLoader.cancel(cancelUrl);
                break;
        }
    }


    @Override
    public void onAttachedToModule(FlutterPlugin.FlutterPluginBinding binding) {
        super.onAttachedToModule(binding);
        initParam();
    }

    @Override
    public void onDetachedFromModule(FlutterPlugin.FlutterPluginBinding binding) {
        super.onDetachedFromModule(binding);
        destroyParam();
    }

    @Override
    protected String buildMethodChannel() {
        return "plugins.flutter_aliplayer_media_loader";
    }

    @Override
    protected String buildEventChannel() {
        return "flutter_aliplayer_media_loader_event";
    }
}