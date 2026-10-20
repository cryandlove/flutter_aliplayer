import 'package:flutter/services.dart';

import 'flutter_avpdef.dart';

typedef OnCompletion = void Function(String url);
@deprecated
typedef OnError = void Function(String url, int code, String msg);
typedef OnCancel = void Function(String url);
typedef OnErrorV2 = void Function(String url, String code, String msg);

class FlutterAliPlayerMediaLoader {
  static MethodChannel methodChannel =
      MethodChannel("plugins.flutter_aliplayer_media_loader");

  static EventChannel eventChannel =
      EventChannel("flutter_aliplayer_media_loader_event");

  static FlutterAliPlayerMediaLoader? _instance;

  FlutterAliPlayerMediaLoader._() {
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  static FlutterAliPlayerMediaLoader _getInstance() {
    if (_instance == null) {
      return FlutterAliPlayerMediaLoader._();
    }
    return _instance!;
  }

  factory FlutterAliPlayerMediaLoader() => _getInstance();

  OnCompletion? _onCompletion;
  OnCancel? _onCancel;
  OnError? _onErrorListener;
  OnErrorV2? _onErrorV2;

  /// 开始加载文件
  void load(String url, int duration) async {
    var map = {"url": url, "duration": "${duration}"};
    await methodChannel.invokeMethod("load", map);
  }

  /// 开始加载文件 + bandwidth
  void loadWithBandWidth(String url, int duration, int? bandWidth) async {
    var map = {"url": url, "duration": "${duration}"};
    if (null != bandWidth) {
      map = {"url": url, "duration": "${duration}", "bandWidth": "$bandWidth"};
    }
    await methodChannel.invokeMethod("load", map);
  }

  /// 恢复加载
  void resume(String url) async {
    await methodChannel.invokeMethod("resume", url);
  }

  /// 暂停加载
  void pause(String url) async {
    await methodChannel.invokeMethod("pause", url);
  }

  /// 取消加载
  void cancel(String url) async {
    await methodChannel.invokeMethod("cancel", url);
  }

  /// 监听预加载相关回调
  /// onCompletion: 完成回调
  /// onCancel: 取消回调
  /// onError: 错误回调
  void setOnLoadStatusListener(OnCompletion? onCompletion, OnCancel? onCancel,
      OnError? onError, OnErrorV2? OnErrorV2) {
    this._onCompletion = onCompletion;
    this._onCancel = onCancel;
    this._onErrorListener = onError;
    this._onErrorV2 = OnErrorV2;
  }

  /// MediaLoader 设置完成监听
  void setOnCompletion(OnCompletion? onCompletion) {
    this._onCompletion = onCompletion;
  }

  /// MediaLoader 设置取消监听
  /// [OnCancel] 预加载取消监听
  void setOnCancel(OnCancel? cancel) {
    this._onCancel = cancel;
  }

  /// MediaLoader 设置错误监听
  ///
  /// [setOnErrorV2]  请使用setOnErrorV2
  @deprecated
  void setOnError(OnError? error) {
    this._onErrorListener = error;
  }

  /// MediaLoader 设置错误V2监听(推荐)
  /// [OnErrorV2]
  void setOnErrorV2(OnErrorV2? error) {
    this._onErrorV2 = error;
  }

  ///回调分发
  void _onEvent(dynamic event) {
    String method = event[EventChanneldef.TYPE_KEY];
    switch (method) {
      case "onError":
        String errorUrl = event["url"];
        String errorCode = event["code"];
        String errorMsg = event["msg"];
        if (null != _onErrorListener) {
          _onErrorListener!(errorUrl, int.parse(errorCode), errorMsg);
        }
        break;
      case "onCompleted":
        String completeUrl = event["url"];
        if (null != _onCompletion) {
          _onCompletion!(completeUrl);
        }
        break;
      case "onCancel":
        String cancelUrl = event["url"];
        if (null != _onCancel) {
          _onCancel!(cancelUrl);
        }
        break;
      case "onErrorV2":
        String errorV2Url = event["url"];
        String errorV2Code = event["code"];
        String errorV2Msg = event["msg"];
        if (null != _onErrorV2) {
          _onErrorV2!(errorV2Url, errorV2Code, errorV2Msg);
        }
        break;
    }
  }

  void _onError(dynamic error) {}
}
