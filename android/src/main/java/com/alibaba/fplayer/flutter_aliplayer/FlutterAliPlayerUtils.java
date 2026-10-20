package com.alibaba.fplayer.flutter_aliplayer;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.aliyun.player.AliPlayerFactory;
import com.aliyun.player.IPlayer;
import com.aliyun.player.nativeclass.MediaInfo;
import com.aliyun.player.nativeclass.Thumbnail;
import com.aliyun.player.nativeclass.TrackInfo;
import com.cicada.player.utils.FrameInfo;
import com.cicada.player.utils.media.DrmCallback;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

/**
 * @author junhuiYe
 * @date 2024/11/2
 * @brief
 */
public class FlutterAliPlayerUtils {
    public static void executeMediaInfo(MethodChannel.Result result, MediaInfo mediaInfo) {
        if (mediaInfo != null) {
            Map<String, Object> getMediaInfoMap = new HashMap<>();
            getMediaInfoMap.put("title", mediaInfo.getTitle());
            getMediaInfoMap.put("status", mediaInfo.getStatus());
            getMediaInfoMap.put("mediaType", mediaInfo.getMediaType());
            getMediaInfoMap.put("duration", mediaInfo.getDuration());
            getMediaInfoMap.put("transcodeMode", mediaInfo.getTransCodeMode());
            getMediaInfoMap.put("coverURL", mediaInfo.getCoverUrl());
            List<Thumbnail> thumbnail = mediaInfo.getThumbnailList();
            List<Map<String, Object>> thumbailList = new ArrayList<>();
            for (Thumbnail thumb : thumbnail) {
                Map<String, Object> map = new HashMap<>();
                map.put("url", thumb.mURL);
                thumbailList.add(map);
                getMediaInfoMap.put("thumbnails", thumbailList);
            }
            List<TrackInfo> trackInfos = mediaInfo.getTrackInfos();
            List<Map<String, Object>> trackInfoList = new ArrayList<>();
            for (TrackInfo trackInfo : trackInfos) {
                Map<String, Object> map = generateMap(trackInfo);
                trackInfoList.add(map);
            }
            getMediaInfoMap.put("tracks", trackInfoList);
            result.success(getMediaInfoMap);
        }
    }


    /**
     * make map for trackInfo
     *
     * @param trackInfo stream info
     * @return map  trackInfo
     */
    private static Map<String, Object> generateMap(TrackInfo trackInfo) {
        Map<String, Object> map = new HashMap<>();
        map.put("vodFormat", trackInfo.getVodFormat());
        map.put("videoHeight", trackInfo.getVideoHeight());
        map.put("videoWidth", trackInfo.getVideoWidth());
        map.put("subtitleLanguage", trackInfo.getSubtitleLang());
        map.put("trackBitrate", trackInfo.getVideoBitrate());
        map.put("vodFileSize", trackInfo.getVodFileSize());
        map.put("trackIndex", trackInfo.getIndex());
        map.put("trackDefinition", trackInfo.getVodDefinition());
        map.put("audioSampleFormat", trackInfo.getAudioSampleFormat());
        map.put("audioLanguage", trackInfo.getAudioLang());
        map.put("vodPlayUrl", trackInfo.getVodPlayUrl());
        map.put("trackType", trackInfo.getType().ordinal());
        map.put("audioSamplerate", trackInfo.getAudioSampleRate());
        map.put("audioChannels", trackInfo.getAudioChannels());

        return map;
    }


    public static void registerRenderFrameCallback(IPlayer mAliPlayer, FlutterInvokeCallback flutterInvokeCallback) {
        mAliPlayer.setOnRenderFrameCallback(new IPlayer.OnRenderFrameCallback() {
            @Override
            public boolean onRenderFrame(FrameInfo frameInfo) {
                Object result = flutterInvokeCallback.invokeOneParameterFlutterCallback(frameInfo.toString(), "onRenderFrame");
                if (result == null) {
                    return false;
                }
                return (boolean) result;
            }
        });
    }

    public static void registerPreRenderFrameCallback(IPlayer mAliPlayer, FlutterInvokeCallback flutterInvokeCallback) {
        mAliPlayer.setOnPreRenderFrameCallback(new IPlayer.OnPreRenderFrameCallback() {
            @Override
            public boolean onPreRenderFrame(FrameInfo frameInfo) {
                Object result = flutterInvokeCallback.invokeOneParameterFlutterCallback(frameInfo.toString(), "onPreRenderFrame");
                if (result == null) {
                    return false;
                }
                return (boolean) result;
            }
        });
    }

    public static void registerDrmCallback(IPlayer mAliPlayer, FlutterInvokeCallback flutterInvokeCallback) {
        mAliPlayer.setDrmCallback(new DrmCallback() {
            @Override
            public byte[] requestProvision(String s, byte[] bytes) {
                return (byte[]) flutterInvokeCallback.invokeTwoParameterFlutterCallback(s, bytes, "requestProvision");
            }

            @Override
            public byte[] requestKey(byte[] bytes) {
                return (byte[]) flutterInvokeCallback.invokeOneParameterFlutterCallback(bytes, "requestKey");
            }
        });
    }


    public static int dpToPx(@NonNull Context context, float dp) {
        float density = context.getResources().getDisplayMetrics().density;
        return (int) (dp * density + 0.5f); // +0.5f 用于四舍五入
    }


    public static String sdkVersion() {
        return "{\"platform\":\"flutter\",\"flutter-version\":" + ":\"" + AliPlayerFactory.getSdkVersion() + "\"}";
    }
}
