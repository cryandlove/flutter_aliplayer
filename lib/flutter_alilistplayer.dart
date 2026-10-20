import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';

import 'flutter_aliplayer.dart';
export 'flutter_aliplayer.dart';

class FlutterAliListPlayer extends FlutterAliplayer {
  String playerId = 'listPlayerDefault';

  FlutterAliListPlayer.init(String? id) : super.init(id);

  @override

  /// 创建短视频列表播放
  Future<void> create() async {
    var invokeMethod = FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'createAliPlayer', wrapWithPlayerId(arg: PlayerType.PlayerType_List));
    sendCustomEvent("source=flutter");
    return invokeMethod;
  }

  /// 设置预加载的个数
  /// 当前位置的前preloadCount和后preloadCount，默认preloadCount = 2
  Future<void> setPreloadCount(int count) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setPreloadCount", wrapWithPlayerId(arg: count));
  }

  /// 添加vid资源到播放列表中
  Future<void> addVidSource({@required vid, @required uid}) async {
    Map<String, dynamic> info = {'vid': vid, 'uid': uid};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("addVidSource", wrapWithPlayerId(arg: info));
  }

  /// 添加url资源到播放列表中
  Future<void> addUrlSource({@required url, @required uid}) async {
    Map<String, dynamic> info = {'url': url, 'uid': uid};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("addUrlSource", wrapWithPlayerId(arg: info));
  }

  /// 从播放列表中删除指定资源
  Future<void> removeSource(String uid) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("removeSource", wrapWithPlayerId(arg: uid));
  }

  /// 获取当前播放资源的uid
  Future<dynamic> getCurrentUid() {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getCurrentUid", wrapWithPlayerId());
  }

  /// 清除播放列表
  Future<void> clear() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("clear", wrapWithPlayerId());
  }

  /// 设置最大的预缓存的内存大小，默认100M，最小20M
  Future<void> setMaxPreloadMemorySizeMB(int size) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setMaxPreloadMemorySizeMB", wrapWithPlayerId(arg: size));
  }

  /// 指定默认的清晰度，如"LD、HD"等
  Future<void> setDefinition(String definition) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setDefinition", wrapWithPlayerId(arg: definition));
  }

  /// 当前位置移动到下一个进行准备播放
  /// 没有入参是url播放方式；有入参是sts播放方式，需要更新sts信息
  Future<void> moveToNext(
      {String? accId, String? accKey, String? token, String? region}) async {
    Map<String, dynamic> info = {
      'accId': accId,
      'accKey': accKey,
      'token': token,
      'region': region
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("moveToNext", wrapWithPlayerId(arg: info));
  }

  /// 当前位置移动到上一个进行准备播放
  /// 没有入参是url播放方式；有入参是sts播放方式，需要更新sts信息
  Future<void> moveToPre({
    String? accId,
    String? accKey,
    String? token,
    String? region,
  }) async {
    Map<String, dynamic> info = {
      'accId': accId,
      'accKey': accKey,
      'token': token,
      'region': region
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("moveToPre", wrapWithPlayerId(arg: info));
  }

  ///移动到指定位置开始准备播放,url播放方式只需要填写uid；sts播放方式，需要更新sts信息
  ///uid 指定资源的uid，代表在列表中的唯一标识
  Future<void> moveTo(
      {@required String? uid,
      String? accId,
      String? accKey,
      String? token,
      String? region}) async {
    Map<String, dynamic> info = {
      'uid': uid,
      'accId': accId,
      'accKey': accKey,
      'token': token,
      'region': region
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("moveTo", wrapWithPlayerId(arg: info));
  }

  @override
  void setOnPrepared(OnPrepared? prepared) {
    this.onPrepared = prepared;
    FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'setOnPrepare', wrapWithPlayerId(arg: (null != onPrepared)));
    if (null != onPrepared) {
      BasicMessageChannel<String> _basicMessageChannel =
          BasicMessageChannel<String>(
        "listPlayer_onPrepare${playerId}",
        StringCodec(),
      );
      // 注册调用 Flutter 端的 callback, 并发送至 Native 端
      _basicMessageChannel.setMessageHandler((String? msg) async {
        Map<String, dynamic> map = jsonDecode(msg!);
        String playerId = map['playerId'];
        String method = map['method'];
        if (null != onPrepared && method == "onPrepared") {
          this.onPrepared!(playerId);
        }
        return '';
      });
    }
  }

  @override
  void setOnRenderingStart(OnRenderingStart renderingStart) {
    this.onRenderingStart = renderingStart;
    FlutterAliPlayerFactory.methodChannel.invokeMethod('setOnRenderingStart',
        wrapWithPlayerId(arg: (null != onRenderingStart)));
    if (null != onRenderingStart) {
      BasicMessageChannel<String> _basicMessageChannel =
          BasicMessageChannel<String>(
        "listPlayer_onRenderingStart${playerId}",
        StringCodec(),
      );
      // 注册调用 Flutter 端的 callback, 并发送至 Native 端
      _basicMessageChannel.setMessageHandler((String? msg) async {
        Map<String, dynamic> map = jsonDecode(msg!);
        String playerId = map['playerId'];
        String method = map['method'];
        if (null != onRenderingStart && method == "onRenderingStart") {
          this.onRenderingStart!(playerId);
        }
        return '';
      });
    }
  }

  @override
  void setOnStateChanged(OnStateChanged? stateChanged) {
    this.onStateChanged = stateChanged;
    FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'setOnStateChanged', wrapWithPlayerId(arg: (null != stateChanged)));
    if (null != stateChanged) {
      BasicMessageChannel<String> _basicMessageChannel =
          BasicMessageChannel<String>(
        "listPlayer_onStateChanged${playerId}",
        StringCodec(),
      );
      // 注册调用 Flutter 端的 callback, 并发送至 Native 端
      _basicMessageChannel.setMessageHandler((String? msg) async {
        Map<String, dynamic> map = jsonDecode(msg!);
        int newState = map['newState'];
        String playerId = map['playerId'];
        String method = map['method'];
        if (null != onStateChanged && method == "onStateChanged") {
          this.onStateChanged!(newState, playerId);
        }
        return '';
      });
    }
  }

  /// 设置ListPlayer 基准预加载时长
  Future<void> updatePreloadConfig(int value) async {
    //setPreloadDuration
    FlutterAliPlayerFactory.methodChannel
        .invokeMethod('updatePreloadConfig', wrapWithPlayerId(arg: value));
  }

  /// 设置预加载场景
  Future<void> setPreloadScene(PreloadScene scene) async {
    FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setPreloadScene', wrapWithPlayerId(arg: scene.index));
  }

  /// 设置 ListPlayer 预加载配置
  Future<void> setMultiBitratesMode(MultiBitratesMode mode) async {
    FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'setMultiBitratesMode', wrapWithPlayerId(arg: mode.index));
  }

  /// 配置动态预加载的递减的offset
  Future<void> enablePreloadStrategy(bool isEnable) async {
    FlutterAliPlayerFactory.methodChannel
        .invokeMethod('enablePreloadStrategy', wrapWithPlayerId(arg: isEnable));
  }

  /// 配置动态预加载的递减的offset
  /// example : setPreloadStrategy("\"algorithm\": \"sub\",\"offset\": \"200\"}");
  Future<void> setPreloadStrategy(String strategyParam) async {
    FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setPreloadStrategy", wrapWithPlayerId(arg: strategyParam));
  }
}
