import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_alilistplayer.dart';
import 'package:flutter_aliplayer/flutter_aliliveshiftplayer.dart';

class FlutterAliPlayerFactory {
  static const MethodChannel methodChannel =
      MethodChannel("plugins.flutter_aliplayer_factory");

  static Map<String, FlutterAliplayer> instanceMap = {};

  /// 创建短视频列表播放
  static FlutterAliListPlayer createAliListPlayer({playerId}) {
    FlutterAliListPlayer flutterAliListPlayer =
        FlutterAliListPlayer.init(playerId);
    flutterAliListPlayer.create();
    return flutterAliListPlayer;
  }

  /// 创建普通播放器
  static FlutterAliplayer createAliPlayer({playerId}) {
    FlutterAliplayer flutterAliplayer = FlutterAliplayer.init(playerId);
    flutterAliplayer.create();
    return flutterAliplayer;
  }

  static FlutterAliLiveShiftPlayer createAliLiveShiftPlayer({playerId}) {
    FlutterAliLiveShiftPlayer flutterAliLiveShiftPlayer =
        FlutterAliLiveShiftPlayer.init(playerId);
    flutterAliLiveShiftPlayer.create();
    return flutterAliLiveShiftPlayer;
  }

  /// 初始化下载秘钥信息
  static Future<void> initService(Uint8List byteData) {
    return methodChannel.invokeMethod("initService", byteData);
  }

  /// 初始化license证书服务
  /// 仅对iOS系统有效
  static Future<void> initLicenseServiceForIOS() {
    return methodChannel.invokeMethod("initLicenseServiceForIOS");
  }

  /// 显示悬浮窗（仅 Android）
  ///
  /// 需要申请系统悬浮窗权限：
  /// ```xml
  /// <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
  /// ```
  /// 调用前请确保已通过 [Settings.canDrawOverlays] 检查并引导用户授权。
  ///
  /// {@macro android_only}
  static void showFloatViewForAndroid(int viewId) {
    if (Platform.isAndroid) {
      methodChannel.invokeMethod("showFloatViewForAndroid", viewId);
    }
  }

  /// 隐藏悬浮窗（仅 Android）
  ///
  /// 需要申请系统悬浮窗权限（同上）。
  /// 调用后将移除当前显示的悬浮窗。
  ///
  /// {@macro android_only}
  static void hideFloatViewForAndroid() {
    if (Platform.isAndroid) {
      methodChannel.invokeMethod("hideFloatViewForAndroid");
    }
  }

  ///  检查悬浮窗权限 （仅 Android）
  ///
  ///  检查应用是否拥有悬浮窗权限
  static Future<bool> checkFloatViewPermission() async {
    if (Platform.isAndroid) {
      return await methodChannel.invokeMethod("checkFloatViewPermission");
    } else {
      return true;
    }
  }

  /// 请求悬浮窗权限（仅 Android）
  ///
  /// 引导用户前往系统设置页面授权悬浮窗权限。
  /// {@macro android_only}
  static Future<bool> requestFloatViewPermission() async {
    if (Platform.isAndroid) {
      return await methodChannel.invokeMethod("requestFloatViewPermission");
    } else {
      return true;
    }
  }

  /// 设置悬浮窗图标（仅 Android）
  ///
  /// 可自定义关闭按钮和返回按钮的图标资源路径。
  /// 图片需为本地 asset 路径
  ///
  /// 需要悬浮窗权限（同上）。
  ///
  /// {@macro android_only}
  static void setFloatViewIcon({String? closeButton, String? backButton}) {
    if (Platform.isAndroid) {
      methodChannel.invokeMethod("setFloatViewIcon", {
        'closeButton': closeButton,
        'backButton': backButton,
      });
    }
  }

  /// 设置悬浮窗图标是否显示（仅 Android）
  ///
  /// 可自定义关闭按钮和返回按钮的图标显示
  ///
  /// 需要悬浮窗权限（同上）。
  ///
  /// {@macro android_only}
  static void setFloatViewUIVisible(bool enable) {
    if (Platform.isAndroid) {
      FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setFloatViewUI",
        enable,
      );
    }
  }

  /// 选择sdk
  static void loadRtsLibrary(bool isAliPlayerSDK) async {
    if (Platform.isAndroid) {
      methodChannel.invokeMethod("loadRtsLibrary", isAliPlayerSDK);
    }
  }
}
