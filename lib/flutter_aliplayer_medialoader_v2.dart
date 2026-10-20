import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';

class FlutterAliMediaLoaderV2 {
  // MethodChannel
  static MethodChannel _methodChannel =
      MethodChannel("plugins.flutter_aliplayer_loader_v2");

  // EventChannel
  static EventChannel _eventChannel =
      EventChannel("flutter_aliplayer_loader_v2_event");

  /// 全局单例模式
  static FlutterAliMediaLoaderV2? _instance;

  /// AliMediaLoaderV2 异常回调
  ///
  /// [ErrorInfo] 错误信息
  Function(ErrorInfo)? onError;

  /// AliMediaLoaderV2 任务完成监听
  ///
  /// [taskId] 任务id
  ///
  /// [urlOrVid] url 或者 视频videoId
  Function(String taskId, String urlOrVid)? onCompleted;

  /// AliMediaLoaderV2 任务取消监听
  ///
  /// [taskId] 任务id
  ///
  /// [urlOrVid] url 或者 视频videoId
  Function(String taskId, String urlOrVid)? onCanceled;

  /// EventChannel 错误回调 (可选)
  ///
  /// [error] 通道异常回调监听
  Function(dynamic error)? onEventError;

  /// 事件流订阅对象，用于管理 EventChannel 的监听生命周期
  ///
  /// 该订阅对象用于接收来自原生平台的事件通知，包括任务完成、错误、取消等事件。
  StreamSubscription? _eventSubscription;

  /// 私有构造函数
  FlutterAliMediaLoaderV2._() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
          _handleMediaLoaderV2Event,
          onError: _handleEventError,
        );
  }

  /// 获取单例
  static FlutterAliMediaLoaderV2 _getInstance() {
    if (_instance == null) {
      return FlutterAliMediaLoaderV2._();
    }
    return _instance!;
  }

  /// 获取单例
  factory FlutterAliMediaLoaderV2() => _getInstance();

  /// 处理EventChannel事件
  _handleMediaLoaderV2Event(dynamic event) {
    String method = event[EventChanneldef.TYPE_KEY];
    switch (method) {
      case "onError":
        {
          // 错误信息
          Map<String, dynamic> jsonMap = {
            "taskId": event["taskId"],
            "urlOrVid": event["urlOrVid"],
            "errorCode": event["errorCode"],
            "errorMsg": event["errorMsg"],
            "errorExtra": event["errorExtra"],
          };
          onError?.call(ErrorInfo.fromJson(jsonMap));
        }
        break;
      case "onCompleted":
        {
          // 完成信息
          String taskId = event["taskId"];
          String urlOrVid = event["urlOrVid"];
          onCompleted?.call(taskId, urlOrVid);
        }
        break;
      case "onCanceled":
        {
          // 取消信息
          String taskId = event["taskId"];
          String urlOrVid = event["urlOrVid"];
          onCanceled?.call(taskId, urlOrVid);
        }
        break;
    }
  }

  /// 处理 EventChannel 错误
  void _handleEventError(dynamic error) {
    onEventError?.call(error);
  }

  /// 添加任务
  ///
  /// [BaseVideoSource] 视频源
    Future<String> addTask(BaseVideoSource videoSource) {
    if (videoSource is UrlSource) {
      UrlSource urlSource = videoSource;
      return _addPreloadTask(urlSource.toJson());
    } else if (videoSource is VidAuth) {
      VidAuth vidAuth = videoSource;
      return _addPreloadTask(vidAuth.toJson());
    } else if (videoSource is VidSts) {
      VidSts vidSts = videoSource;
      return _addPreloadTask(vidSts.toJson());
    } else {
      throw Exception("不支持的参数");
    }
  }

  /// 添加任务
  ///
  /// [videoSource] 数据源
  Future<String> addUrlTask({required String videoSource}) {
    UrlSource urlSource = UrlSource(
      videoUrl: videoSource,
    );
    return _addPreloadTask(urlSource.toJson());
  }

  /// 添加任务
  ///
  /// [vid] 视频ID
  ///
  /// [playAuth] 播放凭证
  Future<String> addVidAuthTask({
    required String vid,
    required String playAuth,
  }) {
    VidAuth vidAuth = VidAuth(
      vid: vid,
      playAuth: playAuth,
    );
    return _addPreloadTask(vidAuth.toJson());
  }

  /// 添加任务
  ///
  /// [vid] 视频ID
  ///
  /// [accessKeyId] 访问密钥ID
  ///
  /// [accessKeySecret] 访问密钥密钥
  ///
  /// [securityToken] 访问密钥令牌
  Future<String> addVidStsTask({
    required String vid,
    required String accessKeyId,
    required String accessKeySecret,
    required String securityToken,
  }) {
    VidSts vidSts = VidSts(
      vid: vid,
      securityToken: securityToken,
      accessKeyId: accessKeyId,
      accessKeySecret: accessKeySecret,
    );
    return _addPreloadTask(vidSts.toJson());
  }

  /// 恢复任务
  ///
  /// [taskId] 任务ID
  void resumeTask(String taskId) {
    _resumePreloadTask(taskId);
  }

  /// 恢复任务
  ///
  /// [taskId] 任务ID
  void pauseTask(String taskId) {
    _pausePreloadTask(taskId);
  }

  /// 取消任务
  ///
  /// [taskId 任务ID]
  void cancelTask(String taskId) {
    _cancelPreloadTask(taskId);
  }

  /// 获取 PreloadConfig
  ///
  /// 由于实例是单实例，所以PreloadConfig 全局唯一，重新添加任务时记得重新设置PreloadConfig，可以调用[resetPreloadConfig()] 或者 setPreloadConfig(PreloadConfig)
  Future<PreloadConfig> getPreloadConfig() async {
    final result = await _methodChannel.invokeMethod("getPreloadConfig");
    final Map<String, dynamic> preloadConfigMap =
        Map<String, dynamic>.from(result as Map);
    return PreloadConfig.fromJson(preloadConfigMap);
  }

  /// 设置 PreloadConfig
  ///
  /// 由于实例是单实例，所以PreloadConfig 全局唯一，重新添加任务时记得重新设置PreloadConfig，可以调用[resetPreloadConfig()] 或者 setPreloadConfig(PreloadConfig)
  void setPreloadConfig(PreloadConfig config) {
    _methodChannel.invokeMethod(
      "setPreloadConfig",
      config.toJson(),
    );
  }

  /// 重建 PreloadConfig，使其回到初始值
  ///
  /// 由于实例是单实例，所以PreloadConfig 全局唯一，重新添加任务时记得重新设置PreloadConfig，可以调用[resetPreloadConfig()] 或者 setPreloadConfig(PreloadConfig)
  void resetPreloadConfig() {
    _methodChannel.invokeMethod("resetPreloadConfig");
  }

  /// 添加任务 Map 数据，返回taskID
  Future<String> _addPreloadTask(Map<String, dynamic> map) async {
    return await _methodChannel.invokeMethod("addTask", map);
  }

  /// 暂停指定 taskId 的任务
  ///
  /// [taskId] 任务ID
  void _pausePreloadTask(String taskId) {
    _methodChannel.invokeMethod("pauseTask", {"taskId": taskId});
  }

  /// 恢复指定 taskId 的任务
  ///
  /// [taskId] 任务ID
  void _resumePreloadTask(String taskId) async {
    _methodChannel.invokeMethod("resumeTask", {"taskId": taskId});
  }

  /// 取消指定 taskId 的任务
  ///
  /// [taskId] 任务ID
  void _cancelPreloadTask(String taskId) async {
    _methodChannel.invokeMethod("cancelTask", {"taskId": taskId});
  }

  /// 释放资源，取消事件订阅
  ///
  /// 主要是取消对 `_eventChannel` 的监听，防止内存泄漏。
  /// 应该在不再需要该实例时调用此方法（例如页面销毁时）
  void dispose() {
      _eventSubscription?.cancel();
      _eventSubscription = null;
  }
}

/// 媒体加载任务错误信息类
/// 用于封装预加载任务的错误详情
class ErrorInfo {
  /// 任务ID
  final String taskId;

  /// URL或VID
  final String urlOrVid;

  /// 错误码
  final String errorCode;

  /// 错误信息（可选）
  final String? errorMsg;

  /// 额外错误信息（可选）
  final String? errorExtra;

  /// 构造函数
  ErrorInfo({
    required this.taskId,
    required this.urlOrVid,
    required this.errorCode,
    this.errorMsg,
    this.errorExtra,
  });

  /// 从Map创建实例
  factory ErrorInfo.fromJson(Map<String, dynamic> json) {
    return ErrorInfo(
      taskId: json['taskId'],
      urlOrVid: json['urlOrVid'],
      errorCode: json['errorCode'],
      errorMsg: json['errorMsg'],
      errorExtra: json['errorExtra'],
    );
  }

  /// 转换为Map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'taskId': taskId,
      'urlOrVid': urlOrVid,
      'errorCode': errorCode,
    };

    // 只有非空值才添加到结果中
    if (errorMsg != null) {
      data['errorMsg'] = errorMsg;
    }
    if (errorExtra != null) {
      data['errorExtra'] = errorExtra;
    }

    return data;
  }

  @override
  String toString() {
    return 'ErrorInfo(taskId: $taskId, urlOrVid: $urlOrVid, errorCode: $errorCode, errorMsg: $errorMsg, errorExtra: $errorExtra)';
  }
}
