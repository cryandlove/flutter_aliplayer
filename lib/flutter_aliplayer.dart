import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_alilistplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_aliplayer/flutter_avpdef.dart';

export 'flutter_avpdef.dart';

typedef OnPrepared = void Function(String playerId);

typedef OnRenderingStart = void Function(String playerId);
typedef OnVideoSizeChanged = void Function(
    int width, int height, int? rotation, String playerId);
typedef OnSnapShot = void Function(String path, String playerId);
typedef OnSeekComplete = void Function(String playerId);
typedef OnSeiData = void Function(
    int type, Uint8List uuid, Uint8List data, String playerId);

typedef OnLoadingBegin = void Function(String playerId);
typedef OnLoadingProgress = void Function(
    int percent, double? netSpeed, String playerId);
typedef OnLoadingEnd = void Function(String playerId);

typedef OnStateChanged = void Function(int newState, String playerId);

typedef OnSubtitleExtAdded = void Function(
    int trackIndex, String url, String playerId);
typedef OnSubtitleShow = void Function(
    int trackIndex, int subtitleID, String subtitle, String playerId);
typedef OnSubtitleHide = void Function(
    int trackIndex, int subtitleID, String playerId);
typedef OnSubtitleHeader = void Function(
    int trackIndex, String head, String playerId);
typedef OnTrackReady = void Function(String playerId);
typedef OnSubTrackReady = void Function(String playerId);
typedef OnVideoRendered = void Function(int? timeMs, int? pts, String playerId);
typedef OnInfo = void Function(
    int? infoCode, int? extraValue, String? extraMsg, String playerId);
typedef OnError = void Function(
    int errorCode, String? errorExtra, String? errorMsg, String playerId);
typedef OnCompletion = void Function(String playerId);

typedef OnTrackChanged = void Function(dynamic value, String playerId);

typedef OnThumbnailPreparedSuccess = void Function(String playerId);
typedef OnThumbnailPreparedFail = void Function(String playerId);

typedef OnThumbnailGetSuccess = void Function(
    Uint8List bitmap, Int64List range, String playerId);
typedef OnThumbnailGetFail = void Function(String playerId);

typedef OnSeekLiveCompletion = void Function(int playTime, String playerId);
typedef OnTimeShiftUpdater = void Function(
    int currentTime, int shiftStartTime, int shiftEndTime, String playerId);
typedef OnStreamSwitchedSuccess = void Function(String url);
typedef OnStreamSwitchedFail = void Function(
    String url, int errorCode, String errorMsg);

typedef OnEventReportParams = void Function(Map params, String playerId);
typedef OnPipStatusChanged = void Function(bool playing, String playerId);
typedef OnWillStartPip = void Function(bool pipStatus, String playerId);
typedef OnWillStopPip = void Function(bool pipStatus, String playerId);
typedef OnLogInfoCallback = void Function(int level, String strlog);

typedef OnURLSourceExpiredCallBack = Future<String?> Function(
    String? expiredUrl);

typedef OnAuthSourceExpiredCallBack = Future<VidAuth?> Function(
    VidAuth? expiredVidAuth);

class FlutterAliplayer {
  OnPipStatusChanged? _onPipStatusChanged;
  OnWillStartPip? _onWillStartPip;
  OnWillStopPip? _onWillStopPip;
  OnLoadingBegin? _onLoadingBegin;
  OnLoadingProgress? _onLoadingProgress;
  OnLoadingEnd? _onLoadingEnd;
  OnPrepared? onPrepared;
  OnRenderingStart? onRenderingStart;
  OnVideoSizeChanged? _onVideoSizeChanged;
  OnSeekComplete? _onSeekComplete;
  OnStateChanged? onStateChanged;
  OnInfo? _onInfo;
  OnCompletion? _onCompletion;
  OnTrackReady? _onTrackReady;
  OnSubTrackReady? _onSubTrackReady;
  OnVideoRendered? _onVideoRendered;
  OnError? _onErrorListener;
  OnSeiData? _onSeiData;
  OnSnapShot? _onSnapShot;
  OnTrackChanged? _onTrackChanged;
  OnThumbnailPreparedSuccess? _onThumbnailPreparedSuccess;
  OnThumbnailPreparedFail? _onThumbnailPreparedFail;

  OnThumbnailGetSuccess? _onThumbnailGetSuccess;
  OnThumbnailGetFail? _onThumbnailGetFail;

  //外挂字幕
  OnSubtitleExtAdded? _onSubtitleExtAdded;
  OnSubtitleHide? _onSubtitleHide;
  OnSubtitleShow? _onSubtitleShow;
  OnSubtitleHeader? _onSubtitleHeader;

  //直播时移
  OnSeekLiveCompletion? _onSeekLiveCompletion;
  OnTimeShiftUpdater? _onTimeShiftUpdater;

  //直播流清晰度切换
  OnStreamSwitchedSuccess? _onStreamSwitchedSuccess;
  OnStreamSwitchedFail? _onStreamSwitchedFail;

  // OnURLSourceExpiredListener? _onURLSourceExpiredListener;

  OnURLSourceExpiredCallBack? _onURLSourceExpiredCallBack;
  OnAuthSourceExpiredCallBack? _onAuthSourceExpiredCallBack;

  BasicMessageChannel<String?>? _onURLExpiredMessageChannel;
  BasicMessageChannel<String?>? _onAuthExpiredMessageChannel;

  //埋点
  OnEventReportParams? _onEventReportParams;

  static OnLogInfoCallback? _onLogInfoCallback = null;

  // static MethodChannel channel = new MethodChannel('flutter_aliplayer');
  EventChannel _eventChannel = EventChannel("flutter_aliplayer_event");
  String playerId = 'default';

  FlutterAliplayer.init(String? id) {
    if (id != null) {
      playerId = id;
    } else {
      playerId = this.hashCode.toString(); //playerViewId
    }
    FlutterAliPlayerFactory.instanceMap[playerId] = this;
    _register();
  }

  void _register() {
    _eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);

    _onURLExpiredMessageChannel = BasicMessageChannel<String?>(
      "aliPlayer_onURLSourceExpiredListener${playerId}",
      StringCodec(),
    );

    _onAuthExpiredMessageChannel = BasicMessageChannel<String?>(
      "aliPlayer_OnVidAuthExpiredListener${playerId}",
      StringCodec(),
    );
  }

  void _dispose() {
    _onURLExpiredMessageChannel?.setMessageHandler(null);
    _onURLExpiredMessageChannel = null;

    _onAuthExpiredMessageChannel?.setMessageHandler(null);
    _onAuthExpiredMessageChannel = null;
    FlutterAliPlayerFactory.instanceMap.remove(playerId);
  }

  /// 播放器事件回调，准备完成事件
  void setOnPrepared(OnPrepared? prepared) {
    this.onPrepared = prepared;
    FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'setOnPrepare', wrapWithPlayerId(arg: (null != onPrepared)));
    if (null != onPrepared) {
      BasicMessageChannel<String> _basicMessageChannel =
          BasicMessageChannel<String>(
        "aliPlayer_onPrepare${playerId}",
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

  /// 播放器事件回调，首帧显示事件
  void setOnRenderingStart(OnRenderingStart renderingStart) {
    this.onRenderingStart = renderingStart;
    FlutterAliPlayerFactory.methodChannel.invokeMethod('setOnRenderingStart',
        wrapWithPlayerId(arg: (null != onRenderingStart)));
    if (null != onRenderingStart) {
      BasicMessageChannel<String> _basicMessageChannel =
          BasicMessageChannel<String>(
        "aliPlayer_onRenderingStart${playerId}",
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

  /// 视频大小变化回调
  void setOnVideoSizeChanged(OnVideoSizeChanged videoSizeChanged) {
    this._onVideoSizeChanged = videoSizeChanged;
  }

  /// 获取截图回调
  void setOnSnapShot(OnSnapShot snapShot) {
    this._onSnapShot = snapShot;
  }

  // 播放器事件回调，跳转完成事件
  void setOnSeekComplete(OnSeekComplete seekComplete) {
    this._onSeekComplete = seekComplete;
  }

  /// 错误代理回调
  void setOnError(OnError onError) {
    this._onErrorListener = onError;
  }

  /// SEI回调
  void setOnSeiData(OnSeiData seiData) {
    this._onSeiData = seiData;
  }

  /// 视频缓冲相关回调
  /// loadingBegin: 播放器事件回调，缓冲开始事件
  /// loadingProgress: 视频缓冲进度回调
  /// loadingEnd: 播放器事件回调，缓冲完成事件
  void setOnLoadingStatusListener(
      {required OnLoadingBegin loadingBegin,
      required OnLoadingProgress loadingProgress,
      required OnLoadingEnd loadingEnd}) {
    this._onLoadingBegin = loadingBegin;
    this._onLoadingProgress = loadingProgress;
    this._onLoadingEnd = loadingEnd;
  }

  /// 画中画播放状态
  /// pipStatusChanged：播放器状态
  /// willStartPip：画中画将要开始
  /// willStopPip：画中画将要结束
  void setPipController(
      {required OnPipStatusChanged pipStatusChanged,
      required OnWillStartPip willStartPip,
      required OnWillStopPip willStopPip}) {
    this._onPipStatusChanged = pipStatusChanged;
    this._onWillStartPip = willStartPip;
    this._onWillStopPip = willStopPip;
  }

  /// 播放器状态改变回调
  void setOnStateChanged(OnStateChanged? stateChanged) {
    this.onStateChanged = stateChanged;
    FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'setOnStateChanged', wrapWithPlayerId(arg: (null != stateChanged)));
    if (null != stateChanged) {
      BasicMessageChannel<String> _basicMessageChannel =
          BasicMessageChannel<String>(
        "aliPlayer_onStateChanged${playerId}",
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

  /// 视频当前播放位置回调
  ///
  /// OnInfo 接口回调
  ///
  /// [InfoCode] InfoCode 信息码
  ///
  /// [extraValue]  信息值
  ///
  /// [extraMsg] 信息内容
  void setOnInfo(OnInfo info) {
    this._onInfo = info;
  }

  /// 播放器事件回调，播放完成事件
  void setOnCompletion(OnCompletion completion) {
    this._onCompletion = completion;
  }

  /// 获取track信息回调
  void setOnTrackReady(OnTrackReady onTrackReady) {
    this._onTrackReady = onTrackReady;
  }

  /// 获取 子流 track信息回调
  void setOnSubTrackReady(OnSubTrackReady onSubTrackReady) {
    this._onSubTrackReady = onSubTrackReady;
  }

  /// 播放器渲染信息回调
  void setOnVideoRendered(OnVideoRendered onVideoRendered) {
    this._onVideoRendered = onVideoRendered;
  }

  /// track切换完成回调
  void setOnTrackChanged(OnTrackChanged onTrackChanged) {
    this._onTrackChanged = onTrackChanged;
  }

  void setOnThumbnailPreparedListener(
      {required OnThumbnailPreparedSuccess preparedSuccess,
      required OnThumbnailPreparedFail preparedFail}) {
    this._onThumbnailPreparedSuccess = preparedSuccess;
    this._onThumbnailPreparedFail = preparedFail;
  }

  /// 获取缩略图相关回调
  /// onThumbnailGetSuccess: 获取缩略图成功回调
  /// onThumbnailGetFail: 获取缩略图失败回调
  void setOnThumbnailGetListener(
      {required OnThumbnailGetSuccess onThumbnailGetSuccess,
      required OnThumbnailGetFail onThumbnailGetFail}) {
    this._onThumbnailGetSuccess = onThumbnailGetSuccess;
    this._onThumbnailGetSuccess = onThumbnailGetSuccess;
  }

  /// 字幕显示回调
  void setOnSubtitleShow(OnSubtitleShow onSubtitleShow) {
    this._onSubtitleShow = onSubtitleShow;
  }

  /// 字幕隐藏回调
  void setOnSubtitleHide(OnSubtitleHide onSubtitleHide) {
    this._onSubtitleHide = onSubtitleHide;
  }

  /// 字幕头信息回调
  /// ass字幕，如果实现了此回调，则播放器不会渲染字幕，由调用者完成渲染，否则播放器自动完成字幕的渲染
  void setOnSubtitleHeader(OnSubtitleHeader onSubtitleHeader) {
    this._onSubtitleHeader = onSubtitleHeader;
  }

  /// 外挂字幕被添加
  void setOnSubtitleExtAdded(OnSubtitleExtAdded onSubtitleExtAdded) {
    this._onSubtitleExtAdded = onSubtitleExtAdded;
  }

  void setOnSeekLiveCompletion(OnSeekLiveCompletion seekLiveCompletion) {
    this._onSeekLiveCompletion = seekLiveCompletion;
  }

  void setOnTimeShiftUpdater(OnTimeShiftUpdater timeShiftUpdater) {
    this._onTimeShiftUpdater = timeShiftUpdater;
  }

  /// 设置切换清晰度监听（直播流）
  Future<void> setOnStreamSwitchedListener(
      OnStreamSwitchedSuccess? onSuccess, OnStreamSwitchedFail? onFail) async {
    if (null != onSuccess && null != onFail) {
      this._onStreamSwitchedSuccess = onSuccess;
      this._onStreamSwitchedFail = onFail;
    }

    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setOnStreamSwitchedListener", {"playerId": this.playerId.toString()});
  }

  /// 埋点事件参数回调
  void setOnEventReportParams(OnEventReportParams eventReportParams) {
    this._onEventReportParams = eventReportParams;
  }

  ///接口部分
  wrapWithPlayerId({arg = ''}) {
    var map = {"arg": arg, "playerId": this.playerId.toString()};
    return map;
  }

  /// 创建播放器
  Future<void> create() async {
    var invokeMethod = FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'createAliPlayer', wrapWithPlayerId(arg: PlayerType.PlayerType_Single));
    // sendCustomEvent("source=flutter");
    return invokeMethod;
  }

  /// 设置播放器的视图playerView
  Future<void> setPlayerView(int viewId) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setPlayerView', wrapWithPlayerId(arg: viewId));
  }

  /// 使用url方式来播放视频
  Future<void> setUrl(String url) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setUrl', wrapWithPlayerId(arg: url));
  }

  /// 直播流 切换清晰度
  Future<void> switchStream(String url) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("switchStream", wrapWithPlayerId(arg: url));
  }

  /// 播放准备
  Future<void> prepare() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('prepare', wrapWithPlayerId());
  }

  /// 开始播放
  Future<void> play() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('play', wrapWithPlayerId());
  }

  /// 暂停播放
  Future<void> pause() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('pause', wrapWithPlayerId());
  }

  /// 清空画面
  Future<void> clearScreen() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('clearScreen', wrapWithPlayerId());
  }

  /// 清空同步画面
  Future<void> clearScreenSync() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('clearScreenSync', wrapWithPlayerId());
  }

  /// 截图
  /// 信息可在获取截图回调中取得
  Future<dynamic> snapshot(String path) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('snapshot', wrapWithPlayerId(arg: path));
  }

  /// 停止播放
  Future<void> stop() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('stop', wrapWithPlayerId());
  }

  /// 销毁播放器(同步)
  Future<void> release() async {
    _dispose();
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('destroy', wrapWithPlayerId());
  }

  /// 异步释放播放器
  Future<void> releaseAsync() async {
    _dispose();
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('releaseAsync', wrapWithPlayerId());
  }

  /// 跳转到指定的播放位置
  /// [position] - 跳转位置
  /// [seekMode] - Seek 模式，类型为 [SeekMode]
  Future<void> seekTo(int position, int seekMode) async {
    var map = {"position": position, "seekMode": seekMode};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("seekTo", wrapWithPlayerId(arg: map));
  }

  /// 以指定位置起播，每次prepare前调用，仅生效一次。（用于代替原先的起播前seek的方案）
  /// [position] - 跳转位置
  /// [seekMode] - Seek 模式，类型为 [SeekMode]
  Future<void> setStartTime(int time, int seekMode) async {
    var map = {"time": time, "seekMode": seekMode};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setStartTime", wrapWithPlayerId(arg: map));
  }

  /// 设置播放器特定功能选项。
  ///
  /// 通过键值对配置播放器的底层行为。
  ///
  /// **常用配置项：**
  ///
  /// 1. **[FlutterAvpdef.ALLOW_PRE_RENDER] (Key: 2)**
  ///    - **含义**：是否开启预渲染能力。
  ///    - **取值**：`1` (开启), `0` (关闭)。
  ///    - **示例**：
  ///      ```dart
  ///      aliplayer.setOption(FlutterAvpdef.ALLOW_PRE_RENDER, 1);
  ///      ```
  ///
  /// 2. **[FlutterAvpdef.SCENARIO_FLAG] (Key: 7)**
  ///    - **含义**：单例播放器场景标识。
  ///    - **取值**：根据具体业务场景自定义。
  ///    - **示例**：
  ///      ```dart
  ///      aliplayer.setOption(FlutterAvpdef.SCENARIO_FLAG, "Custom Scene");
  ///      ```
  Future<void> setOption(int opt1, Object opt2) async {
    var map = {"opt1": opt1, "opt2": opt2};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setOption", wrapWithPlayerId(arg: map));
  }

  /// 设置精准seek的最大间隔
  Future<void> setMaxAccurateSeekDelta(int delta) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setMaxAccurateSeekDelta", wrapWithPlayerId(arg: delta));
  }

  /// 当前是否循环播放
  Future<dynamic> isLoop() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('isLoop', wrapWithPlayerId());
  }

  /// 设置是否循环播放
  Future<void> setLoop(bool isloop) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setLoop', wrapWithPlayerId(arg: isloop));
  }

  /// 当前是否自动播放
  Future<dynamic> isAutoPlay() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('isAutoPlay', wrapWithPlayerId());
  }

  /// 设置是否自动播放
  Future<void> setAutoPlay(bool isAutoPlay) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setAutoPlay', wrapWithPlayerId(arg: isAutoPlay));
  }

  /// 设置视频快速启动
  Future<void> setFastStart(bool fastStart) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setFastStart", wrapWithPlayerId(arg: fastStart));
  }

  /// 当前是否静音
  Future<dynamic> isMuted() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('isMuted', wrapWithPlayerId());
  }

  /// 设置是否静音
  Future<void> setMuted(bool isMuted) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setMuted', wrapWithPlayerId(arg: isMuted));
  }

  /// 当前是否开启硬件解码
  Future<dynamic> enableHardwareDecoder() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('enableHardwareDecoder', wrapWithPlayerId());
  }

  /// 设置是否开启硬件解码
  Future<void> setEnableHardwareDecoder(bool isHardWare) async {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'setEnableHardwareDecoder', wrapWithPlayerId(arg: isHardWare));
  }

  /// 软解码时生效，是否只返回底层音频数据地址，mAudioDataAddr默认为false,
  /// 是否只返回底层视频数据地址，默认为true
  Future<void> setRenderFrameCallbackConfig(
      bool mAudioData, bool mVideoData) async {
    var map = {"mAudioData": mAudioData, "mVideoData": mVideoData};
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        'setRenderFrameCallbackConfig', wrapWithPlayerId(arg: map));
  }

  /// 用vid和sts来播放视频
  /// sts可参考：https://help.aliyun.com/document_detail/28756.html?spm=a2c4g.11186623.4.4.6f554c07q7B7aS
  /// playConfig 从[generatePlayerConfig]获取
  Future<void> setVidSts(
      {String? vid,
      String? region,
      String? accessKeyId,
      String? accessKeySecret,
      String? securityToken,
      String? playConfig,
      List<String>? definitionList,
      String quality = "",
      bool forceQuality = false,
      playerId}) async {
    Map<String, dynamic> stsInfo = {
      "vid": vid,
      "region": region,
      "accessKeyId": accessKeyId,
      "accessKeySecret": accessKeySecret,
      "securityToken": securityToken,
      "definitionList": definitionList,
      "playConfig": playConfig,
      "quality": quality,
      "forceQuality": forceQuality
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setVidSts", wrapWithPlayerId(arg: stsInfo));
  }

  /// 使用vid+playauth方式播放
  /// 可参考：https://help.aliyun.com/document_detail/57294.html
  /// playConfig 从[generatePlayerConfig]获取
  Future<void> setVidAuth(
      {String? vid,
      String? region,
      String? playAuth,
      String? playConfig,
      List<String>? definitionList,
      String quality = "",
      bool forceQuality = false,
      playerId}) async {
    Map<String, dynamic> authInfo = {
      "vid": vid,
      "region": region,
      "playAuth": playAuth,
      "definitionList": definitionList,
      "playConfig": playConfig,
      "quality": quality,
      "forceQuality": forceQuality
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setVidAuth", wrapWithPlayerId(arg: authInfo));
  }

  /// 用vid和MPS信息来播放视频
  /// 可参考：https://help.aliyun.com/document_detail/53522.html?spm=5176.doc53534.2.5.mhSfOh
  Future<void> setVidMps(Map<String, dynamic> mpsInfo) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setVidMps", wrapWithPlayerId(arg: mpsInfo));
  }

  /// 使用LiveSts 方式播放直播流
  Future<void> setLiveSts(
      {String? url,
      String? accessKeyId,
      String? accessKeySecret,
      String? securityToken,
      String? region,
      String? domain,
      String? app,
      String? stream,
      EncryptionType? encryptionType,
      List<String>? definitionList,
      playerId}) async {
    Map<String, dynamic> liveStsInfo = {
      "url": url,
      "accessKeyId": accessKeyId,
      "accessKeySecret": accessKeySecret,
      "securityToken": securityToken,
      "region": region,
      "domain": domain,
      "app": app,
      "stream": stream,
      "encryptionType": encryptionType?.index.toString(),
      "definitionList": definitionList,
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setLiveSts", wrapWithPlayerId(arg: liveStsInfo));
  }

  /// 更新LiveSts信息
  Future<dynamic> updateLiveStsInfo(
      String accId, String accKey, String token, String region) async {
    Map<String, String> liveStsInfo = {
      "accId": accId,
      "accKey": accKey,
      "token": token,
      "region": region,
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('updateLiveStsInfo', wrapWithPlayerId(arg: liveStsInfo));
  }

  /// 获取渲染旋转模式
  Future<dynamic> getRotateMode() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getRotateMode', wrapWithPlayerId());
  }

  /// 设置渲染旋转模式
  /// [RotateMode]
  Future<void> setRotateMode(int mode) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setRotateMode', wrapWithPlayerId(arg: mode));
  }

  /// 获取渲染填充模式
  Future<dynamic> getScalingMode() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getScalingMode', wrapWithPlayerId());
  }

  /// 设置渲染填充模式
  /// [ScaleMode] 渲染填充模式
  Future<void> setScalingMode(int mode) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setScalingMode', wrapWithPlayerId(arg: mode));
  }

  /// 设置输出声道，若输入源是双声道，则支持切换为左声道、右声道；若输入源是单声道，则设置无效。该设置会同时影响音频渲染及PCM数据回调
  Future<void> setOutputAudioChannel(int chanel) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setOutputAudioChannel', wrapWithPlayerId(arg: chanel));
  }

  /// 获取渲染镜像模式
  Future<dynamic> getMirrorMode() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getMirrorMode', wrapWithPlayerId());
  }

  /// 获取Alpha渲染模式
  Future<dynamic> getAlphaRenderMode() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getAlPhaRenderMode', wrapWithPlayerId());
  }

  /// Alpha渲染模式，支持alpha在右侧、左侧、上侧、下侧，默认值无
  ///
  /// [AlphaRenderMode] 透明通道渲染模式
  Future<void> setAlphaRenderMode(int mode) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setAlphaRenderMode', wrapWithPlayerId(arg: mode));
  }

  /// 设置渲染镜像模式
  Future<void> setMirrorMode(int mode) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setMirrorMode', wrapWithPlayerId(arg: mode));
  }

  /// 获取播放速率
  Future<dynamic> getSpeed() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getSpeed', wrapWithPlayerId());
  }

  /// 设置播放速率
  /// 0.5-2.0之间，1为正常播放
  Future<void> setSpeed(double speed) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setSpeed', wrapWithPlayerId(arg: speed));
  }

  /// 设置视频的背景色
  Future<void> setVideoBackgroundColor(var color) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setVideoBackgroundColor', wrapWithPlayerId(arg: color));
  }

  /// 获取视频的宽度
  Future<dynamic> getVideoWidth() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getVideoWidth', wrapWithPlayerId());
  }

  /// 获取视频的高度
  Future<dynamic> getVideoHeight() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getVideoHeight', wrapWithPlayerId());
  }

  /// 获取视频的旋转角度
  Future<dynamic> getVideoRotation() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getVideoRotation', wrapWithPlayerId());
  }

  /// 设置播放器的音量（非系统音量）
  /// 范围0.0~2.0，当音量大于1.0时，可能出现噪音，不推荐使用
  Future<void> setVolume(double volume) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('setVolume', wrapWithPlayerId(arg: volume));
  }

  /// 获取播放器的音量（非系统音量）
  Future<dynamic> getVolume() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getVolume', wrapWithPlayerId());
  }

  /// 获取视频的长度
  Future<int> getDuration() async {
    int value = await FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getDuration', wrapWithPlayerId());
    return value;
  }

  /// 获取当前播放位置
  Future<dynamic> getCurrentPosition() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getCurrentPosition', wrapWithPlayerId());
  }

  /// 获取当前播放位置的utc时间
  Future<dynamic> getCurrentUtcTime() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getCurrentUtcTime', wrapWithPlayerId());
  }

  /// 获取当前播放命中的缓存文件大小
  Future<dynamic> getLocalCacheLoadedSize() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getLocalCacheLoadedSize', wrapWithPlayerId());
  }

  /// 获取当前下载速度
  ///
  /// 返回当前的下载速度，单位为 bps (bits per second)
  Future<int> getCurrentDownloadSpeed() async {
    final result = await FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getCurrentDownloadSpeed', wrapWithPlayerId());
    return result as int;
  }

  /// 获取已经缓存的位置
  Future<dynamic> getBufferedPosition() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('getBufferedPosition', wrapWithPlayerId());
  }

  /// 获取播放器设置
  Future<dynamic> getConfig() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getConfig", wrapWithPlayerId());
  }

  /// 获取播放器设置
  /// 新版本增加，逐步替代[getConfig]
  Future<AVPConfig> getPlayConfig() async {
    Map map = await FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getPlayConfig", wrapWithPlayerId());
    return AVPConfig.convertAt(map);
  }

  /// 获取播放器时长
  Future<dynamic> getPlayedDuration() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getPlayedDuration", wrapWithPlayerId());
  }

  /// 播放器设置，传递map
  Future<void> setConfig(Map map) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setConfig", wrapWithPlayerId(arg: map));
  }

  /// 播放器设置
  /// 新版本增加，逐步替代[setConfig]
  Future<void> setPlayConfig(AVPConfig config) async {
    Map map = config.convertToMap();

    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setPlayConfig", wrapWithPlayerId(arg: map));
  }

  /// 播放器降级设置
  /// source 降级url
  /// config 降级配置
  Future<void> enableDowngrade(String source, AVPConfig config) async {
    Map map = {
      "source": source,
      "config": config.convertToMap(),
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("enableDowngrade", wrapWithPlayerId(arg: map));
  }

  /// 设置滤镜配置
  /// 在prepare之前调用此方法。如果想更新，调用updateFilterConfig
  Future<void> setFilterConfig(String configJson) async {
    // configJson格式: "[{"target":"<target1>", "options":["<options_key>"]}, {"target":"<target2>", "options":<null>},...]"
    // options_key 目前有两种"sharp"、"sr"
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setFilterConfig", wrapWithPlayerId(arg: configJson));
  }

  /// 更新滤镜配置
  Future<void> updateFilterConfig(String target, Map options) async {
    var map = {'target': target, 'options': options};
    // options格式: {"key":"<options_key>", "value": "<options_value>"}
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("updateFilterConfig", wrapWithPlayerId(arg: map));
  }

  /// 开启关闭滤镜
  Future<void> setFilterInvalid(String target, String invalid) async {
    var map = {'target': target, 'invalid': invalid};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setFilterInvalid", wrapWithPlayerId(arg: map));
  }

  /// 根据url获取缓存的文件名
  Future<dynamic> getCacheFilePath(String url) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getCacheFilePath", wrapWithPlayerId(arg: url));
  }

  /// 根据vid获取缓存的文件名
  Future<dynamic> getCacheFilePathWithVid(
      String vid, String format, String definition) async {
    var map = {'vid': vid, 'format': format, 'definition': definition};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getCacheFilePathWithVid", wrapWithPlayerId(arg: map));
  }

  /// 根据vid+试看时长获取缓存的文件名
  Future<dynamic> getCacheFilePathWithVidAtPreviewTime(
      String vid, String format, String definition, String previewTime) async {
    var map = {
      'vid': vid,
      'format': format,
      'definition': definition,
      'previewTime': previewTime
    };
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "getCacheFilePathWithVidAtPreviewTime", wrapWithPlayerId(arg: map));
  }

  /// 获取媒体信息，包括track信息
  Future<dynamic> getMediaInfo() {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getMediaInfo", wrapWithPlayerId());
  }

  /// 获取媒体子流信息，包括track信息
  Future<dynamic> getSubMediaInfo() {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getSubMediaInfo", wrapWithPlayerId());
  }

  /// 获取当前播放track
  ///
  /// please use [currentTrack]
  @deprecated
  Future<AVPTrackInfo?> getCurrentTrack(int trackIdx) async {
    try {
      Map<dynamic, dynamic> result = await FlutterAliPlayerFactory.methodChannel
          .invokeMethod("getCurrentTrack", wrapWithPlayerId(arg: trackIdx));
      return AVPTrackInfo.fromJson(result);
    } on PlatformException catch (_) {
      // throw Exception("数据获取异常 ${e.message}");
      return null;
    }
  }

  /// 获取当前播放track
  ///
  /// [TrackType] trackInfo 的类型
  Future<AVPTrackInfo?> currentTrack(TrackType trackIdx) async {
    try {
      dynamic result = await FlutterAliPlayerFactory.methodChannel.invokeMethod(
          "getCurrentTrack", wrapWithPlayerId(arg: trackIdx.index));
      if (null != result && result is Map) {
        Map<dynamic, dynamic> resultMap = result;
        return AVPTrackInfo.fromJson(resultMap);
      }
      return null;
    } on PlatformException catch (_) {
      // throw Exception("数据获取异常 ${e.message}");
      return null;
    }
  }

  /// 设置缩略图URL
  Future<dynamic> createThumbnailHelper(String thumbnail) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "createThumbnailHelper", wrapWithPlayerId(arg: thumbnail));
  }

  /// 获取指定位置的缩略图
  Future<dynamic> requestBitmapAtPosition(int position) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "requestBitmapAtPosition", wrapWithPlayerId(arg: position));
  }

  /// 设置traceID，用于跟踪debug信息
  /// 通过埋点事件回调onEventReportParams
  Future<dynamic> setTraceID(String traceID) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setTraceID", wrapWithPlayerId(arg: traceID));
  }

  /// 添加外挂字幕
  Future<void> addExtSubtitle(String url) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("addExtSubtitle", wrapWithPlayerId(arg: url));
  }

  /// 选择外挂字幕
  Future<void> selectExtSubtitle(int trackIndex, bool enable) {
    var map = {'trackIndex': trackIndex, 'enable': enable};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("selectExtSubtitle", wrapWithPlayerId(arg: map));
  }

  /// 设置多码率时默认播放的码率
  /// 将会选择与之最接近的一路流播放
  Future<void> setDefaultBandWidth(int bandWidth) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setDefaultBandWidth", wrapWithPlayerId(arg: bandWidth));
  }

  /// 设置多码率时默认播放的清晰度
  /// 将会选择与之最接近的一路流播放
  Future<void> setDefaultResolution(int resolution) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setDefaultResolution", wrapWithPlayerId(arg: resolution));
  }

  /// 设置多码率时默认播放的音频流
  /// 将会选择与之最接近的一路流播放
  Future<void> setDefaultAudioLanguage(String language) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setDefaultAudioLanguage", wrapWithPlayerId(arg: language));
  }

  /// 设置多码率时默认播放的字幕流
  /// 将会选择与之最接近的一路流播放
  Future<void> setDefaultSubtitleLanguage(String language) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setDefaultSubtitleLanguage", wrapWithPlayerId(arg: language));
  }

  /// 获取当前播放所使用的视频播放服务（VPS）信息
  /// 返回值为服务端标识字符串，可能为空
  Future<dynamic> getCurrentVps() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getCurrentVps", wrapWithPlayerId());
  }

  /// 设置播放器场景
  /// 根据播放器场景调整适合的场景
  Future<void> setPlayerScene(PlayerScene scene) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setPlayerScene", wrapWithPlayerId(arg: scene.index));
  }

  /// 根据trackIndex，切换清晰度
  /// trackIdx 选择清晰度的index，-1代表自适应码率
  ///  accurate 0 为不精确  1 为精确  不填为忽略
  Future<void> selectTrack(
    int trackIdx, {
    int accurate = -1,
  }) {
    var map = {
      'trackIdx': trackIdx,
      'accurate': accurate,
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("selectTrack", wrapWithPlayerId(arg: map));
  }

  Future<void> setPrivateService(Int8List data) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setPrivateService", data);
  }

  /// 设置期望使用的播放器名字
  Future<void> setPreferPlayerName(String playerName) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setPreferPlayerName", wrapWithPlayerId(arg: playerName));
  }

  /// 为画中画功能设置显示模式
  Future<void> setPictureInPictureShowMode(int showMode) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setPictureInPictureShowMode", wrapWithPlayerId(arg: showMode));
  }

  /// 获取播放时使用的播放器名字
  Future<dynamic> getPlayerName() {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getPlayerName", wrapWithPlayerId());
  }

  /// 发送用户自定义事件
  /// 通过埋点事件回调onEventReportParams
  Future<void> sendCustomEvent(String args) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("sendCustomEvent", wrapWithPlayerId(arg: args));
  }

  /// 设置UserData，用于一些全局API的透传，以区分player实例。
  Future<void> setUserData(String userData) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setUserData", wrapWithPlayerId(arg: userData));
  }

  /// 设置UserData，用于一些全局API的透传，以区分player实例。
  Future<dynamic> getUserData() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getUserData", wrapWithPlayerId());
  }

  /// 设置某路流相对于主时钟的延时时间
  /// 默认是0, 目前只支持外挂字幕
  Future<void> setStreamDelayTime(int trackIdx, int time) {
    var map = {'index': trackIdx, 'time': time};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setStreamDelayTime", wrapWithPlayerId(arg: map));
  }

  /// 重新加载
  /// 比如网络超时时，可以重新加载。
  Future<void> reload() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod('reload', wrapWithPlayerId());
  }

  /// 获取播放器的参数
  Future<dynamic> getOption(AVPOption key) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("getOption", wrapWithPlayerId(arg: key.index.toString()));
  }

  /// 根据key获取相应的信息
  Future<dynamic> getPropertyString(AVPPropertyKey key) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "getPropertyString", wrapWithPlayerId(arg: key.index.toString()));
  }

  /// 设置埋点事件回调onEventReportParams代理
  Future<dynamic> setEventReportParamsDelegate(int argt) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setEventReportParamsDelegate", wrapWithPlayerId(arg: argt.toString()));
  }

  /// 设置画中画功能开启/关闭
  /// 仅对iOS系统有效，在iOS 15以上系统应用
  /// 需要在onPrepared回调方法中调用
  Future<dynamic> setPictureInPictureEnableForIOS(bool enable) {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setPictureInPictureEnableForIOS",
        wrapWithPlayerId(arg: enable.toString()));
  }

  ///静态方法
  /// 获取SDK版本号信息
  static Future<dynamic> getSDKVersion() async {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod("getSDKVersion");
  }

  /// 获取设备UUID
  static Future<dynamic> getDeviceUUID() async {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod("getDeviceUUID");
  }

  /// 返回某项功能是否支持
  /// type 是否支持的功能的类型。 参考SupportFeatureType。
  static Future<bool> isFeatureSupport(SupportFeatureType type) async {
    bool boolV = await FlutterAliPlayerFactory.methodChannel
        .invokeMethod("isFeatureSupport", type.index);
    return boolV;
  }

  /// 控制音频设置
  /// 默认按照播放器SDK自身设置，只对iOS平台有效
  /// 替代旧版本的[enableMix]
  static Future<void> setAudioSessionTypeForIOS(
      AliPlayerAudioSesstionType type) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setAudioSessionTypeForIOS", type.index);
  }

  /// 是否打开log输出
  static Future<void> enableConsoleLog(bool enable) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("enableConsoleLog", enable);
  }

  /// 设置日志打印回调block
  /// logLevel log输出级别
  /// [LogLevel] 输出级别
  static Future<void> setLogLevel(int level) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setLogLevel", level);
  }

  /// 设置日志打印回调
  /// [OnLogInfoCallback]
  static Future<void> setLogInfoCallBack(OnLogInfoCallback? callback) async {
    _onLogInfoCallback = callback;
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setLogInfoBlock", {"arg": null != callback});
  }

  /// 设置帧级别日志
  /// value 0代表关闭 1代表打开
  static Future<void> setLogOption(int value) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setLogOption", value);
  }

  /// 获取日志级别
  /// 开启帧级别日志的情况下，日志级别为trace
  /// [LogLevel] 日志级别
  static Future<int> getLogLevel() async {
    int logLevel = await FlutterAliPlayerFactory.methodChannel.invokeMethod(
      "getLogLevel",
    );
    return logLevel;
  }

  /// 设置是否使用http2
  static Future<void> setUseHttp2(bool use) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setUseHttp2", use);
  }

  /// 是否开启httpDNS
  /// 默认不开启
  static Future<void> enableHttpDns(bool enable) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("enableHttpDns", enable);
  }

  /// 设置域名对应的解析ip
  /// host 域名，需指定端口（http默认端口80，https默认端口443）。例如player.alicdn.com:443
  /// ip 相应的ip，设置为空字符串清空设定。
  static Future<void> setDNSResolve(String host, String ip) {
    Map map = {
      "host": host,
      "ip": ip,
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setDNSResolve", map);
  }

  /// 设置解析ip类型
  static Future<void> setIpResolveType(AVPIpResolveType type) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setIpResolveType", type.index.toString());
  }

  /// 设置fairPlay的用户证书id
  /// 仅对iOS系统有效
  static Future<void> setFairPlayCertIDForIOS(String certID) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setFairPlayCertIDForIOS", certID);
  }

  /// 设置是否使能硬件提供的音频变速播放能力
  /// 关闭后则使用软件实现音频的倍速播放，pcm回调数据的格式和此设置关联；默认打开
  static Future<void> enableHWAduioTempo(bool enable) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("enableHWAduioTempo", enable);
  }

  /// 强制音频渲染器采用指定的格式进行渲染
  /// 如果设定的格式设备不支持，则无效，无效值将被忽略，使用默认值；pcm回调数据的格式和此设置关联；默认关闭
  static Future<void> forceAudioRendingFormat(
      String force, String fmt, String channels, String sample_rate) {
    var map = {
      'force': force,
      'fmt': fmt,
      'channels': channels,
      'sample_rate': sample_rate
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("forceAudioRendingFormat", map);
  }

  /// 重连所有网络连接
  /// 网络路由发生变化后，调用此接口，可以让播放器所有的连接切换到新的路由上去。
  static Future<void> netWorkReConnect() {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("netWorkReConnect");
  }

  /// 开启本地缓存
  /// 开启之后，就会缓存到本地文件中。
  /// [setCacheFileClearConfig] 缓存相关配置
  static Future<void> enableLocalCache(bool enable, String maxBufferMemoryKB,
      String localCacheDir, DocTypeForIOS docTypeForIOS) {
    var map = {
      'enable': enable,
      'maxBufferMemoryKB': maxBufferMemoryKB,
      'localCacheDir': localCacheDir,
    };

    if (Platform.isIOS) {
      // docTypeForIOS的取值代表沙盒目录路径类型 "0":Documents, "1":Library, "2":Caches, 其他:Documents
      map['docTypeForIOS'] = docTypeForIOS.index.toString();
    } else {
      // 安卓不需设置docType，直接传递localCacheDir
    }

    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("enableLocalCache", map);
  }

  /// 本地缓存文件自动清理相关的设置
  static Future<void> setCacheFileClearConfig(
      String expireMin, String maxCapacityMB, String freeStorageMB) {
    var map = {
      'expireMin': expireMin,
      'maxCapacityMB': maxCapacityMB,
      'freeStorageMB': freeStorageMB,
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setCacheFileClearConfig", map);
  }

  /// 是否开启内建预加载网络平衡策略，播放过程中，自动控制预加载的运行时机。默认开启。
  /// enable 是否开启
  static Future<void> enableNetworkBalance(bool enable) {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("enableNetworkBalance", enable);
  }

  /// 清理本地缓存，需要先应用配置缓存，才能清理本地缓存
  static Future<void> clearCaches() {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod("clearCaches");
  }

  ///return deviceInfo
  static Future<dynamic> createDeviceInfo() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("createDeviceInfo");
  }

  ///type : {FlutterAvpdef.BLACK_DEVICES_H264 / FlutterAvpdef.BLACK_DEVICES_HEVC}
  static Future<void> addBlackDevice(String type, String model) async {
    var map = {
      'black_type': type,
      'black_device': model,
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("addBlackDevice", map);
  }

  /// 创建媒体播放自定义设置对象
  static Future<void> createVidPlayerConfigGenerator() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("createVidPlayerConfigGenerator");
  }

  /// 设置预览时间
  /// previewTime 预览时间，单位为秒
  /// 调用之前必须先执行[createVidPlayerConfigGenerator]
  static Future<void> setPreviewTime(int previewTime) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setPreviewTime", previewTime.toString());
  }

  /// HLS标准加密设置UriToken
  /// mtsHlsUriToken 字符串
  /// 调用之前必须先执行[createVidPlayerConfigGenerator]
  static Future<void> setHlsUriToken(String mtsHlsUriToken) async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setHlsUriToken", mtsHlsUriToken);
  }

  /// 添加vid的playerconfig参数
  /// key: 对应playerConfig中的参数名字
  /// value: 对应key参数的值
  /// 调用之前必须先执行[createVidPlayerConfigGenerator]
  /// Android 设置加密类型：key 为 EncryptType，value 可选：Unencrypted，AliyunVoDEncryption，HLSEncryption
  static Future<void> addVidPlayerConfigByStringValue(
      String key, String value) async {
    Map param = {key: value};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("addVidPlayerConfigByStringValue", param);
  }

  /// 添加vid的playerconfig参数
  /// key: 对应playerConfig中的参数名字
  /// value: 对应key参数的整形值
  /// 调用之前必须先执行[createVidPlayerConfigGenerator]
  static Future<void> addVidPlayerConfigByIntValue(
      String key, int value) async {
    Map param = {key: value.toString()};
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("addVidPlayerConfigByIntValue", param);
  }

  /// 添加vid的playerconfig参数
  /// 加密类型 EncryptType
  /// 调用之前必须先执行[createVidPlayerConfigGenerator]
  static Future<void> setEncryptType(EncryptType type) async {
    int encryptType = EncryptType.values.indexOf(type);
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("setEncryptType", encryptType);
  }

  /// 生成playerConfig
  /// 调用之前必须先执行[createVidPlayerConfigGenerator]
  static Future<String> generatePlayerConfig() async {
    return await FlutterAliPlayerFactory.methodChannel
        .invokeMethod("generatePlayerConfig");
  }

  /// 设置加载url的hash值回调。如果不设置，SDK使用md5算法。
  Future<void> setDrmCallback(Function(Object, Object) requestProvision,
      Function(Object, Object) requestKey) async {
    BasicMessageChannel<String> _basicMessageChannel =
        BasicMessageChannel<String>(
      "requestProvision",
      StringCodec(),
    );
    BasicMessageChannel<String> _basicMessageChannel2 =
        BasicMessageChannel<String>(
      "requestKey",
      StringCodec(),
    );
    // 注册调用 Flutter 端的 callback, 并发送至 Native 端
    _basicMessageChannel.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        Object object1 = parsedArguments["param1"];
        Object object2 = parsedArguments["param2"];
        String result = requestProvision(object1, object2);
        // 处理接收到的消息
        return result; // 返回结果给 Native
      }
      return "";
    });

    _basicMessageChannel2.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        Object object1 = parsedArguments["param1"];
        Object object2 = parsedArguments["param2"];
        String result = requestKey(object1, object2);
        // 处理接收到的消息
        return result; // 返回结果给 Native
      }
      return "";
    });

    try {
      await FlutterAliPlayerFactory.methodChannel
          .invokeMethod('setDrmCallback');
    } on PlatformException catch (e) {
      print("Failed to register callback: '${e.message}'.");
    }
  }

  /// 设置预渲染帧回调。
  Future<void> setOnPreRenderFrameCallback(
      Function(Object) onPreRenderFrame) async {
    BasicMessageChannel<String> _basicMessageChannel =
        BasicMessageChannel<String>(
      "onPreRenderFrame",
      StringCodec(),
    );
    // 注册调用 Flutter 端的 callback, 并发送至 Native 端
    _basicMessageChannel.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        Object frameInfo = parsedArguments["param1"];
        bool result = onPreRenderFrame(frameInfo);
        // 处理接收到的消息
        return result.toString(); // 返回结果给 Native
      }
      return "false";
    });

    try {
      await FlutterAliPlayerFactory.methodChannel
          .invokeMethod('setOnPreRenderFrameCallback', wrapWithPlayerId());
    } on PlatformException catch (e) {
      print("Failed to register callback: '${e.message}'.");
    }
  }

  void setOnURLSourceExpiredListener(
      {required OnURLSourceExpiredCallBack call}) async {
    _onURLSourceExpiredCallBack = call;

    // 注册调用 Flutter 端的 callback, 并发送至 Native 端
    _onURLExpiredMessageChannel?.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        String expiredUrl = parsedArguments["expiredUrl"];
        String? result = await _onURLSourceExpiredCallBack!(expiredUrl);
        return result; // 返回结果给 Native
      }
      return null;
    });

    await FlutterAliPlayerFactory.methodChannel.invokeMethod(
      "setOnURLSourceExpiredListener",
      wrapWithPlayerId(
        arg: true,
      ),
    );
  }

  void removeOnURLSourceExpiredListener() async {
    _onURLSourceExpiredCallBack = null;
    _onURLExpiredMessageChannel?.setMessageHandler(null);
    await FlutterAliPlayerFactory.methodChannel.invokeMethod(
      "setOnURLSourceExpiredListener",
      wrapWithPlayerId(
        arg: false,
      ),
    );
  }

  void setOnVidAuthExpiredListener(
      {required OnAuthSourceExpiredCallBack call}) async {
    _onAuthSourceExpiredCallBack = call;
// 注册调用 Flutter 端的 callback, 并发送至 Native 端
    _onAuthExpiredMessageChannel?.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        VidAuth vidAuth = new VidAuth(
          vid: parsedArguments["videoId"],
          playAuth: parsedArguments["playAuth"],
        );

        if (parsedArguments.containsKey("region") &&
            null != parsedArguments["region"]) {
          vidAuth.region = parsedArguments["region"];
        }

        VidAuth? newAuthInfo = await _onAuthSourceExpiredCallBack!(vidAuth);
        if (null != newAuthInfo) {
          return jsonEncode(newAuthInfo.toJson()); // 返回结果给 Native
        } else {
          return null;
        }
      }
      return null;
    });

    await FlutterAliPlayerFactory.methodChannel.invokeMethod(
      "setOnVidAuthExpiredListener",
      wrapWithPlayerId(
        arg: true,
      ),
    );
  }

  void removeOnVidAuthExpiredListener() async {
    _onAuthSourceExpiredCallBack = null;
    _onAuthExpiredMessageChannel?.setMessageHandler(null);

    await FlutterAliPlayerFactory.methodChannel.invokeMethod(
      "setOnVidAuthExpiredListener",
      wrapWithPlayerId(
        arg: false,
      ),
    );
  }

  /// 设置渲染帧回调。
  Future<void> setOnRenderFrameCallback(Function(Object) onRenderFrame) async {
    BasicMessageChannel<String> _basicMessageChannel =
        BasicMessageChannel<String>(
      "onRenderFrame",
      StringCodec(),
    );
// 注册调用 Flutter 端的 callback, 并发送至 Native 端
    _basicMessageChannel.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        Object frameInfo = parsedArguments["param1"];
        bool result = onRenderFrame(frameInfo);
// 处理接收到的消息
        return result.toString(); // 返回结果给 Native
      }
      return "false";
    });

    try {
      await FlutterAliPlayerFactory.methodChannel
          .invokeMethod('setOnRenderFrameCallback', wrapWithPlayerId());
    } on PlatformException catch (e) {
      print("Failed to register callback: '${e.message}'.");
    }
  }

  /// 播放前转换播放URL。
  /// 对于视频播放，请在播放前尝试转换播放URL
  Future<void> setConvertURLCallback(Function(String, String) callback) async {
// print("[FB->F] registerConvertURLCallback");
    BasicMessageChannel<String> _basicMessageChannel =
        BasicMessageChannel<String>(
      "convertURL",
      StringCodec(),
    );
// 注册调用 Flutter 端的 callback, 并发送至 Native 端
    _basicMessageChannel.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        String s1 = parsedArguments["param1"];
        String s2 = parsedArguments["param2"];
// print("[F->D] registerConvertURLCallback callback: $s1, $s2");
        String result = callback(s1, s2);
// print("[F->FB] registerConvertURLCallback result: $result");
// 处理接收到的消息
        return result; // 返回结果给 Native
      }
      return "";
    });

    try {
// print("[FB->F] setConvertURLCallback");
      await FlutterAliPlayerFactory.methodChannel
          .invokeMethod('setConvertURLCallback', wrapWithPlayerId());
// print("[F->D] setConvertURLCallback return");
    } on PlatformException catch (e) {
      print("Failed to register callback: '${e.message}'.");
    }
  }

  /// 启动画中画（Picture in Picture），仅 iOS 可用。
  ///
  /// 调用前需要先通过 [setPictureInPictureEnableForIOS] 开启播放器画中画能力，
  /// 并确保播放器处于播放状态。
  ///
  /// 注意：该方法依赖 `pipController` 已存在。该控制器通常在系统首次触发画中画
  ///（例如用户点击 Home 键 / 上滑进入后台）时由 SDK 创建并赋值，
  /// 若尚未生成，调用本方法不会生效。
  ///
  /// Android 平台调用此方法无任何效果。
  Future<void> startPip() async {
    if (Platform.isIOS) {
      await FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "startPip",
        wrapWithPlayerId(),
      );
    }
  }

  /// 停止画中画（Picture in Picture），仅 iOS 可用。
  ///
  /// 调用后会关闭系统画中画窗口，但不会销毁播放器实例。
  /// 如需释放播放器，建议先调用此方法并等待画中画完全停止后再 [release]。
  ///
  /// Android 平台调用此方法无任何效果。
  Future<void> stopPip() async {
    if (Platform.isIOS) {
      await FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "stopPip",
        wrapWithPlayerId(),
      );
    }
  }

  ///回调分发
  void _onEvent(dynamic event) {
    String method = event[EventChanneldef.TYPE_KEY];
    String playerId = event['playerId'] ?? '';
    FlutterAliplayer player =
        FlutterAliPlayerFactory.instanceMap[playerId] ?? this;
    switch (method) {
      case "onPrepared":
        if (player.onPrepared != null) {
          player.onPrepared!(playerId);
        }
        break;
      case "onRenderingStart":
        if (player.onRenderingStart != null) {
          player.onRenderingStart!(playerId);
        }
        break;
      case "onVideoSizeChanged":
        if (player._onVideoSizeChanged != null) {
          int width = event['width'];
          int height = event['height'];
          int? rotation = event['rotation'];
          player._onVideoSizeChanged!(width, height, rotation, playerId);
        }
        break;
      case "onSnapShot":
        if (player._onSnapShot != null) {
          String snapShotPath = event['snapShotPath'];
          player._onSnapShot!(snapShotPath, playerId);
        }
        break;
      case "onChangedSuccess":
        break;
      case "onChangedFail":
        break;
      case "onSeekComplete":
        if (player._onSeekComplete != null) {
          player._onSeekComplete!(playerId);
        }
        break;
      case "onSeiData":
        if (player._onSeiData != null) {
          int type = event['type'];
          Uint8List data = event['data'];
          Uint8List uuid = event['uuid'];
          player._onSeiData!(type, uuid, data, playerId);
        }
        break;
      case "onLoadingBegin":
        if (player._onLoadingBegin != null) {
          player._onLoadingBegin!(playerId);
        }
        break;
      case "onLoadingProgress":
        int percent = event['percent'];
        double? netSpeed = event['netSpeed'];
        if (player._onLoadingProgress != null) {
          player._onLoadingProgress!(percent, netSpeed, playerId);
        }
        break;
      case "setPlaying":
        bool playing = event['playing'];
        if (player._onPipStatusChanged != null) {
          player._onPipStatusChanged!(playing, playerId);
        }
        break;
      case "WillStartPip":
        bool playing = event['pipStatus'];
        if (player._onWillStartPip != null) {
          player._onWillStartPip!(playing, playerId);
        }
        break;
      case "WillStopPip":
        bool playing = event['pipStatus'];
        if (player._onWillStopPip != null) {
          player._onWillStopPip!(playing, playerId);
        }
        break;
      case "onLoadingEnd":
        if (player._onLoadingEnd != null) {
          player._onLoadingEnd!(playerId);
        }
        break;
// case "onStateChanged":
//   if (player.onStateChanged != null) {
//     int newState = event['newState'];
//     print("[player][cbk][stateChanged] thisPlayerId :${this.playerId} otherPlayerId ${playerId}  hashCode ${this.hashCode}");
//     player.onStateChanged!(newState, playerId);
//   }
//   break;
      case "onInfo":
        if (player._onInfo != null) {
          int? infoCode = event['infoCode'];
          int? extraValue = event['extraValue'];
          String? extraMsg = event['extraMsg'];
          player._onInfo!(infoCode, extraValue, extraMsg, playerId);
        }
        break;
      case "onError":
        if (player._onErrorListener != null) {
          int errorCode = event['errorCode'];
          String? errorExtra = event['errorExtra'];
          String? errorMsg = event['errorMsg'];
          player._onErrorListener!(errorCode, errorExtra, errorMsg, playerId);
        }
        break;
      case "onCompletion":
        if (player._onCompletion != null) {
          player._onCompletion!(playerId);
        }
        break;
      case "onTrackReady":
        if (player._onTrackReady != null) {
          player._onTrackReady!(playerId);
        }
        break;
      case "onSubTrackReady":
        if (player._onSubTrackReady != null) {
          player._onSubTrackReady!(playerId);
        }
        break;
      case "onVideoRendered":
        if (player._onVideoRendered != null) {
          int timeMs = event['timeMs'];
          int pts = event['pts'];
          player._onVideoRendered!(timeMs, pts, playerId);
        }
        break;
      case "onTrackChanged":
        if (player._onTrackChanged != null) {
          dynamic info = event['info'];
          player._onTrackChanged!(info, playerId);
        }
        break;
      case "thumbnail_onPrepared_Success":
        if (player._onThumbnailPreparedSuccess != null) {
          player._onThumbnailPreparedSuccess!(playerId);
        }
        break;
      case "thumbnail_onPrepared_Fail":
        if (player._onThumbnailPreparedFail != null) {
          player._onThumbnailPreparedFail!(playerId);
        }
        break;
      case "onThumbnailGetSuccess":
        dynamic bitmap = event['thumbnailbitmap'];
        dynamic range = event['thumbnailRange'];
        if (player._onThumbnailGetSuccess != null) {
          if (Platform.isIOS) {
            range = Int64List.fromList(range.cast<int>());
          }
          player._onThumbnailGetSuccess!(bitmap, range, playerId);
        }
        break;
      case "onThumbnailGetFail":
        if (player._onThumbnailGetFail != null) {
          player._onThumbnailGetFail!(playerId);
        }
        break;
      case "onSubtitleExtAdded":
        if (player._onSubtitleExtAdded != null) {
          int trackIndex = event['trackIndex'];
          String url = event['url'];
          player._onSubtitleExtAdded!(trackIndex, url, playerId);
        }
        break;
      case "onSubtitleShow":
        if (player._onSubtitleShow != null) {
          int trackIndex = event['trackIndex'];
          int subtitleID = event['subtitleID'];
          String subtitle = event['subtitle'];
          player._onSubtitleShow!(trackIndex, subtitleID, subtitle, playerId);
        }
        break;
      case "onSubtitleHide":
        if (player._onSubtitleHide != null) {
          int trackIndex = event['trackIndex'];
          int subtitleID = event['subtitleID'];
          player._onSubtitleHide!(trackIndex, subtitleID, playerId);
        }
        break;
      case "onSubtitleHeader":
        if (player._onSubtitleHeader != null) {
          int trackIndex = event['trackIndex'];
          String header = event['header'];
          player._onSubtitleHeader!(trackIndex, header, playerId);
        }
        break;
      case "onUpdater":
        if (player._onTimeShiftUpdater != null) {
          var currentTime = event['currentTime'];
          var shiftStartTime = event['shiftStartTime'];
          var shiftEndTime = event['shiftEndTime'];
          player._onTimeShiftUpdater!(
              currentTime, shiftStartTime, shiftEndTime, playerId);
        }
        break;
      case "onSeekLiveCompletion":
        if (player._onSeekLiveCompletion != null) {
          var playTime = event['playTime'];
          player._onSeekLiveCompletion!(playTime, playerId);
        }
        break;
      case "StreamSwitch_onSwitchedSuccess":
        if (player._onStreamSwitchedSuccess != null) {
          var url = event['url'];
          player._onStreamSwitchedSuccess!(url);
        }
        break;
      case "StreamSwitch_onSwitchedFail":
        if (player._onStreamSwitchedFail != null) {
          var url = event['url'];
          var errorCode = event['errorCode'];
          var errorMsg = event['errorMsg'];
          player._onStreamSwitchedFail!(url, errorCode, errorMsg);
        }
        var url = event['url'];
        print("EventStreamSwitchedFail ${event}, url: $url");
        break;
      case "AliPlayer_LogCallBackInfo":
        if (null != _onLogInfoCallback) {
          String level = event['logLevel'];
          String strLog = event['strLog'];
          _onLogInfoCallback!(int.parse(level), strLog);
        }
        break;
      case "OnURLSourceExpiredListener":
        {
// if (null != player._onURLSourceExpiredListener) {
//   String url = event['url'];
//   print("[AliyunPlayer] OnURLSourceExpiredListener $url");
//   player._onURLSourceExpiredListener!(url);
// }
        }
        break;
      case "onEventReportParams":
        if (player._onEventReportParams != null) {
          var params = event['params'];
          player._onEventReportParams!(params, playerId);
        }
    }
  }

  ///Event error事件处理
  void _onError(dynamic error) {}
}

typedef void AliPlayerViewCreatedCallback(int viewId);

/// AliPlayerView
///
/// this is a Widget for [FlutterAliplayer]
class AliPlayerView extends StatefulWidget {
  final AliPlayerViewCreatedCallback? onCreated;
  final x;
  final y;
  final width;
  final height;
  final AliPlayerViewTypeForAndroid aliPlayerViewType;

  AliPlayerView({
    Key? key,
    @required required this.onCreated,
    @required this.x,
    @required this.y,
    @required this.width,
    @required this.height,
    this.aliPlayerViewType = AliPlayerViewTypeForAndroid.surfaceview,
  });

  @override
  State<StatefulWidget> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<AliPlayerView> {
  @override
  Widget build(BuildContext context) {
    return nativeView();
  }

  StatefulWidget nativeView() {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'flutter_aliplayer_render_view',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: <String, dynamic>{
          "x": widget.x,
          "y": widget.y,
          "width": widget.width,
          "height": widget.height,
          "viewType": widget.aliPlayerViewType.name,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.operatingSystem == 'ohos') {
      return OhosView(
        viewType: 'flutter_aliplayer_render_view',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: <String, dynamic>{
          "x": widget.x,
          "y": widget.y,
          "width": widget.width,
          "height": widget.height,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return UiKitView(
        viewType: 'plugins.flutter_aliplayer',
        // viewType: 'flutter_aliplayer_render_view',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: <String, dynamic>{
          "x": widget.x,
          "y": widget.y,
          "width": widget.width,
          "height": widget.height,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  }

  Future<void> _onPlatformViewCreated(id) async {
    if (widget.onCreated != null) {
      widget.onCreated!(id);
    }
  }
}
