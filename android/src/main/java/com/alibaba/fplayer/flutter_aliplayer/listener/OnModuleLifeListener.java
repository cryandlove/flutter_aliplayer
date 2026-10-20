package com.alibaba.fplayer.flutter_aliplayer.listener;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public interface OnModuleLifeListener {

    void onAttachedToModule(FlutterPlugin.FlutterPluginBinding binding);


    void onDetachedFromModule(FlutterPlugin.FlutterPluginBinding binding);
}
