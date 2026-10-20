import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_avpdef.dart';

class FlutterAliPlayerGlobalSettings {
  static MethodChannel methodChannel =
      MethodChannel("plugins.flutter_global_setting");

  // static EventChannel _eventChannel =
  //     EventChannel("plugins.flutter_global_setting_event");

  /// 国际站环境集成 [GlobalEnv]
  ///
  /// license 配置请参考 [license 集成](https://help.aliyun.com/zh/vod/developer-reference/access-to-license?spm=a2c4g.11186623.help-menu-search-29932.d_3#30d07e0055xr6)
  static Future<void> setGlobalEnvironment(int config) {
    return methodChannel.invokeMethod("setGlobalEnvironment", config);
  }

  /// 设置特定功能选项
  static Future<void> setOption(int opt1, Object opt2) async {
    var map = {"opt1": opt1, "opt2": opt2};
    return methodChannel.invokeMethod("setOption", map);
  }

  /// 播放器实例禁用crash堆栈上传
  static Future<void> disableCrashUpload(bool enable) {
    return methodChannel.invokeMethod("disableCrashUpload", enable);
  }

  /// 是否开启增强型httpDNS
  /// 默认不开启 开启后需要注意以下事项
  /// 1.该功能与Httpdns互斥，若同时打开，后开启的功能会实际生效；
  /// 2.需要申请license的高级httpdns功能，否则该功能不工作
  /// 3.需要通过接口添加cdn域名，否则会降级至local dns。
  static Future<void> enableEnhancedHttpDns(bool enable) {
    return methodChannel.invokeMethod("enableEnhancedHttpDns", enable);
  }

  /// 设置加载url的hash值回调。如果不设置，SDK使用md5算法。
  static Future<void> setCacheUrlHashCallback(
      Function(String) getUrlHashCallback) async {
    const BasicMessageChannel<String> _basicMessageChannel =
        BasicMessageChannel<String>(
      "getUrlHashCallback",
      StringCodec(),
    );
    // 注册调用 Flutter 端的 callback, 并发送至 Native 端
    _basicMessageChannel.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        String url = parsedArguments["param1"];
        String result = getUrlHashCallback(url);
        // 处理接收到的消息
        return result; // 返回结果给 Native
      }
      return "";
    });

    try {
      await methodChannel.invokeMethod('setCacheUrlHashCallback');
    } on PlatformException catch (e) {
      print("Failed to register callback: '${e.message}'.");
    }
  }

  /// 设置网络数据回调。
  /// requestUrl	数据归属的URL
  /// inData	输入数据buffer
  /// inOutSize	输入输出数据buffer大小，单位字节
  /// outData	输出数据buffer，处理后的数据可写入这里，大小必须与inOutSize一样，其内存由sdk内部申请，无需管理内存
  static Future<void> setNetworkCallback(
      bool Function(Object requestUrl, Object inData, Object inOutSize,
              Object outData)
          onNetworkDataProcess) async {
    const BasicMessageChannel<String> _basicMessageChannel =
        BasicMessageChannel<String>(
      "onNetworkDataProcess",
      StringCodec(),
    );
    // 注册调用 Flutter 端的 callback，并发送至 Native 端
    _basicMessageChannel.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        Object requestUrl = parsedArguments["param1"];
        Object inData = parsedArguments["param2"];
        Object inOutSize = parsedArguments["param3"];
        Object outData = parsedArguments["param4"];

        // 调用 onNetworkDataProcess，并确保返回值是 bool 类型
        bool result =
            onNetworkDataProcess(requestUrl, inData, inOutSize, outData);

        // 返回结果给 Native
        return result.toString(); // 返回布尔值给 Native
      }

      // 默认返回 false，如果 message 为 null
      return "false";
    });

    try {
      await methodChannel.invokeMethod('setNetworkCallback');
    } on PlatformException catch (e) {
      print("Failed to register callback: '${e.message}'.");
    }
  }

  /// 设置取BackupUrl回调。
  static Future<void> setAdaptiveDecoderGetBackupURLCallback(
      String Function(Object, Object, Object) getBackupUrlCallback) async {
    const BasicMessageChannel<String> _basicMessageChannel =
        BasicMessageChannel<String>(
      "getBackupUrlCallback",
      StringCodec(),
    );
    // 注册调用 Flutter 端的 callback，并发送至 Native 端
    _basicMessageChannel.setMessageHandler((message) async {
      if (message != null) {
        Map<String, dynamic> parsedArguments = jsonDecode(message);
        Object oriBizType = parsedArguments["param1"];
        Object oriCodecType = parsedArguments["param2"];
        Object oriURL = parsedArguments["param3"];

        String result = getBackupUrlCallback(oriBizType, oriCodecType, oriURL);

        // 返回结果给 Native
        return result;
      }
      return "";
    });

    try {
      await methodChannel
          .invokeMethod('setAdaptiveDecoderGetBackupURLCallback');
    } on PlatformException catch (e) {
      print("Failed to register callback: '${e.message}'.");
    }
  }


  /// 设置系统亮度
  static Future<void> setSystemBrightness(double value) async {
    // 将值限制在 0.0 到 1.0 之间
    final double clampedValue = value.clamp(0.0, 1.0);
    await methodChannel.invokeMethod("setSystemBrightness", {
      "brightness": clampedValue,
    });
  }


  /// 获取系统亮度
  static Future<double?> getSystemBrightness() async {
    return await methodChannel.invokeMethod<double>("getSystemBrightness");
  }
}
