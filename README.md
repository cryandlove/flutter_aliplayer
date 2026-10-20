# flutter_aliplayer

基于阿里云播放器 Flutter 插件 `flutter_aliplayer` 修改的鸿蒙适配版本，在保留 Android、iOS 平台实现的基础上，新增鸿蒙（OHOS）平台的基础播放能力。

## 项目来源

本项目由阿里云 SDK：**`flutter_aliplayer`** 修改而来，是第三方维护的衍生版本，**不是阿里云官方发布版本**。原始播放器能力来自阿里云播放器 SDK，原项目及原作者的版权声明予以保留，感谢阿里云提供的 Flutter 插件及原生播放器能力。

- 原插件：[flutter_aliplayer](https://pub.dev/packages/flutter_aliplayer)
- 本仓库 Flutter 插件版本：`7.18.0`，见 [pubspec.yaml](./pubspec.yaml)。该版本号不代表本仓库已独立发布到 pub.dev。
- 鸿蒙原生播放器依赖：`AliyunPlayer-7.18.0.har`，见 [ohos/oh-package.json5](./ohos/oh-package.json5)。
- 原项目版权与许可声明：见 [LICENSE](./LICENSE)。

本次修改主要位于 Flutter 插件的平台桥接与鸿蒙适配层，不表示重新实现了阿里云原生播放器内核，也不代表获得了阿里云官方认证或背书。

## 本次修改说明

本次适配解决本仓库原有 Flutter 插件仅包含 Android、iOS 播放接入、缺少鸿蒙平台实现的问题：

1. 在插件平台配置中增加 `ohos` 注册项，并新增 ArkTS 插件实现。
2. 在 `AliPlayerView` 中增加鸿蒙 `OhosView` 渲染分支，通过平台视图和 `XComponent` 接入播放画面。
3. 对接阿里云鸿蒙播放器，将 Flutter 方法调用转发到原生播放器，并通过事件通道回传播放事件。
4. 按 `playerId` 管理播放器实例，接入基础播放控制、状态查询及资源释放。
5. 提供包含鸿蒙工程的 [example](./example)，并将示例的插件依赖路径修正为 `../`，避免 `flutter pub get` 因路径不存在而失败。

### 平台与能力范围

| 平台 | 当前实现范围 |
| --- | --- |
| Android | 保留原有平台实现，本次鸿蒙适配不代表已完成 Android 全量回归 |
| iOS | 保留原有平台实现，本次鸿蒙适配不代表已完成 iOS 全量回归 |
| 鸿蒙（OHOS） | 新增基础 URL 播放接入，具体能力与限制见下文 |

鸿蒙侧当前已接入的接口与回调：

- 播放器创建、视图绑定、准备、播放、暂停、停止、同步及异步释放。
- URL 播放源、拖动进度、自动播放、循环播放、静音、音量与倍速设置。
- 当前进度、缓冲位置、时长、视频宽高查询，以及清屏。
- 准备完成、首帧显示、播放完成、拖动完成、错误、信息、加载状态及视频尺寸变化回调。

以上范围根据当前源码列出，不等同于已完成鸿蒙真机全量验证，也不代表 Android、iOS、鸿蒙三端接口完全一致。

### 鸿蒙已知限制

- 尚未接入 VidAuth、VidSts、列表播放、直播时移、下载、预加载、截图、字幕及画面旋转/镜像/缩放等接口；不得直接将后文原有接口示例视为鸿蒙可用能力。
- `setOnStateChanged` 目前仅有注册应答，尚未转发对应的原生状态变化事件。
- `initService`、`initLicenseServiceForIOS` 在鸿蒙侧仍为占位实现，调用成功不表示已完成授权初始化。
- 未实现的方法会返回 `notImplemented`，调用方应避免调用或处理相应的平台异常。
- 当前 Dart 源码直接使用 `OhosView`，需要使用提供该 API 的鸿蒙 Flutter SDK；不能假设标准 Flutter SDK 可直接编译本版本，即使目标是 Android 或 iOS。

## 接入本修改版本

普通的 pub.dev 版本依赖不会自动包含本仓库的修改。接入本版本请使用本地路径，或在本仓库上传 GitHub 后使用 Git 依赖。

### 本地依赖

以下示例假设应用工程与本仓库目录同级，实际路径请按项目结构调整：

```yaml
dependencies:
  flutter_aliplayer:
    path: ../flutter_aliplayer
```

本仓库的 `example` 位于插件内部，因此使用：

```yaml
dependencies:
  flutter_aliplayer:
    path: ../
```

### GitHub 依赖

上传后，将下方 `url` 替换为你的实际仓库地址。生产项目建议通过 `ref` 固定到已验证的提交或标签。

```yaml
dependencies:
  flutter_aliplayer:
    git:
      url: <本仓库的 GitHub 克隆地址>
```

### 鸿蒙环境与示例运行

1. 准备支持 OHOS 的 Flutter SDK、DevEco Studio 与配套鸿蒙开发环境。
2. 确认 [ohos/libs](./ohos/libs) 中的 `AliyunPlayer-7.18.0.har` 已就绪，且与 [ohos/oh-package.json5](./ohos/oh-package.json5) 中的路径一致。`flutter.har` 依赖也需要由配套 Flutter 工具链正确提供或解析。
3. 按自己的环境配置示例工程的 SDK 路径、应用标识、设备签名与网络权限，不要直接沿用其他开发者的本机路径或签名配置。
4. 在 `example` 目录执行以下命令，并选择鸿蒙设备：

```sh
flutter pub get --no-example
flutter devices
flutter run -d <device-id>
```

示例工程当前要求 Dart `^3.11.5`，请同时确认所选鸿蒙 Flutter SDK 的 Dart 版本满足 [example/pubspec.yaml](./example/pubspec.yaml) 中的约束。

## 发布与使用注意事项

- 上传 GitHub 前检查并排除本机绝对路径、签名证书、私钥、访问凭证、构建产物和依赖缓存，不要将个人开发环境配置直接公开。
- 保留原项目的 [LICENSE](./LICENSE) 及版权声明。原生 SDK、HAR 文件及其他第三方组件的授权与分发要求需单独确认，不能仅凭插件源码的许可声明判断。
- 本文记录的是当前仓库的适配情况；使用前请针对目标设备、播放源和业务场景完成构建及真机验证。

## 原有接口参考

以下内容保留自原项目，主要作为 Android、iOS 接入参考，并非本仓库新增功能或三端一致性承诺。部分示例可能与当前 API 存在差异，请以源码为准；鸿蒙侧以本文“平台与能力范围”和“鸿蒙已知限制”为准。

- [Android SDK 文档](https://help.aliyun.com/document_detail/94328.html?spm=a2c4g.11186623.6.979.1d5c67b4gEmBvH)
- [iOS SDK 文档](https://help.aliyun.com/document_detail/94428.html?spm=a2c4g.11186623.6.980.7fc22a88xOI4gc)

### 原项目说明

* Flutter 播放器在原生层是基于 Android 播放器 SDK 和 iOS 播放器 SDK 的。可能部分原生播放器 SDK 的接口有遗漏，在 flutter 播放器插件中没有暴露出来。目前我们已将源码提供出来，开发者可以自行添加。也可以通知给我们，我们会对遗漏的接口进行补充。
* 如果您希望以更高效的方式快速实现视频播放功能，可以尝试使用 **[aliplayer_widget](https://pub.dev/packages/aliplayer_widget)**。这是一款基于 `flutter_aliplayer` 开发的**播放器 Flutter 含 UI 集成方案**，专为快速集成和灵活定制而设计。它支持点播（VOD）、直播、短视频列表播放等多种场景，同时提供丰富的功能模块和高度可定制的 UI 组件，能够显著降低开发成本。您可以通过它轻松构建流畅且高效的视频播放体验。

## 原项目版本号规则

以下为原项目的版本号约定，不表示本仓库同步发布了这两种版本。从 6.17.0 版本开始，原项目并行发布两种版本：

1. 版本号如 6.17.0：
   - 对应 SDK 内核为 **播放器独立SDK（AliPlayerSDK）**，适用于纯点播场景。
2. 版本号如 6.17.0-interactivelive：
   - 对应 SDK 内核为 **音视频终端SDK（AliVCSDK_InteractiveLive）**，适用于点播和直播场景。
   - 若配合推流插件 `flutter_livepush_plugin` 使用，请务必使用此版本，以避免 SDK 编译冲突。

此外，您可以在项目中修改 `useAIOFramework` 变量以动态切换 SDK 内核：

- 设置 `useAIOFramework = false`：使用播放器独立 SDK（默认）。
- 设置 `useAIOFramework = true`：使用音视频终端 SDK。

您还可以根据需要自行更改 SDK 内核版本：

* 设置 `player_sdk_version`：定义播放器独立 SDK 版本号。
* 设置 `aio_sdk_version`：定义音视频终端 SDK 版本号。

请根据具体需求进行选择和调整，以确保最佳使用体验。

## AliPlayer

### 日志设置 + 日志回调

```dart
  /// 设置日志等级
  FlutterAliplayer.setLogLevel(LogLevel.AF_LOG_LEVEL_INFO);
  /// 开启/关闭 日志
  FlutterAliplayer.enableConsoleLog(true);
  // 日志回调信息
  FlutterAliplayer.setLogInfoCallBack((level, msg) {
    print("[LOG][LEVEL][$level] $msg");
  });
  /// 开启帧日志回调，一般在排查问题时打开
  FlutterAliplayer.setLogOption(1);
```


### 1. 播放控制

```dart
  ///1、创建播放器
  FlutterAliplayer fAliplayer = FlutterAliPlayerFactory.createAliPlayer();
  ///多实例播放器创建方式，需要 flutter 层管理 playerId，其他接口一样，在播放器的回调中会返回对应的 playerId 来通知 flutter 层是哪一个播放器对象
  //FlutterAliplayer fAliplayer = FlutterAliPlayerFactory.createAliPlayer(playerId: playerId);

  ///2、设置监听,只列举了部分接口，更多接口可以参考播放器 Android\iOS 接口文档
  ///准备成功
  fAliplayer.setOnPrepared((playerId) {});
  ///首帧显示
  fAliplayer.setOnRenderingStart((playerId) {});
  ///视频宽高变化
  fAliplayer.setOnVideoSizeChanged((width, height,playerId) {});
  ///播放器状态变化
  fAliplayer.setOnStateChanged((newState,playerId) {});
  ///加载状态
  fAliplayer.setOnLoadingStatusListener(
      loadingBegin: (playerId) {},
      loadingProgress: (percent, netSpeed,playerId) {},
      loadingEnd: (playerId) {});
  ///拖动完成
  fAliplayer.setOnSeekComplete((playerId) {});
  ///播放器事件信息回调，包括 buffer、当前播放进度 等等信息，根据 infoCode 来判断，对应 FlutterAvpdef.infoCode
  fAliplayer.setOnInfo((infoCode, extraValue, extraMsg,playerId) {});
  ///播放完成
  fAliplayer.setOnCompletion((playerId) {});
  ///设置流准备完成
  fAliplayer.setOnTrackReady((playerId) {});
  ///截图结果
  fAliplayer.setOnSnapShot((path,playerId) {});
  ///错误结果
  fAliplayer.setOnError((errorCode, errorExtra, errorMsg,playerId) {});
  ///切换流变化
  fAliplayer.setOnTrackChanged((value,playerId) {});

  ///3、设置渲染的 View
  @override
  Widget build(BuildContext context) {
    var x = 0.0;
    var y = 0.0;
    Orientation orientation = MediaQuery.of(context).orientation;
    var width = MediaQuery.of(context).size.width;

    var height;
    if (orientation == Orientation.portrait) {
      height = width * 9.0 / 16.0;
    } else {
      height = MediaQuery.of(context).size.height;
    }
    AliPlayerView aliPlayerView = AliPlayerView(
        onCreated: onViewPlayerCreated,
        x: x,
        y: y,
        width: width,
        height: height);
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Scaffold(
          body: Column(
            children: [
              Container(
                  color: Colors.black,
                  child: aliPlayerView,
                  width: width,
                  height: height),
            ],
          ),
        );
      },
    );
  }

    ///4、设置播放源
    ///说明：STS 播放方式，vid、region、accessKeyId、accessKeySecret、securityToken 为必填，其他参数可选
    ///     AUTH 播放方式，vid、region、playAuth 为必填，其他参数可选
    /// 每个 Map 对应的key 在 flutter 的 Demo 的 config.dart 中查看，fAliplayer 为播放器对象，如果还未创建，参考后续文档创建播放器
  void onViewPlayerCreated(viewId) async {
    ///将 渲染 View 设置给播放器
    fAliplayer.setPlayerView(viewId);
    //设置播放源
    FlutterAliplayer.createVidPlayerConfigGenerator();
    // 设置预览时间
    FlutterAliplayer.setPreviewTime(
        int.parse(_dataSourceMap[DataSourceRelated.PREVIEWTIME_KEY]));
    String playConfig = await FlutterAliplayer.generatePlayerConfig();

    switch (_playMode) {
      //URL 播放方式
      case ModeType.URL:
        this.fAliplayer.setUrl(_dataSourceMap[DataSourceRelated.URL_KEY]);
        break;
      //STS 播放方式
      case ModeType.STS:
        this.fAliplayer.setVidSts(
            vid: _dataSourceMap[DataSourceRelated.VID_KEY],
            region: _dataSourceMap[DataSourceRelated.REGION_KEY],
            accessKeyId: _dataSourceMap[DataSourceRelated.ACCESSKEYID_KEY],
            accessKeySecret:
                _dataSourceMap[DataSourceRelated.ACCESSKEYSECRET_KEY],
            securityToken: _dataSourceMap[DataSourceRelated.SECURITYTOKEN_KEY],
            definitionList: _dataSourceMap[DataSourceRelated.DEFINITION_LIST],
            playConfig: playConfig);
        break;
      //AUTH 播放方式
      case ModeType.AUTH:
        this.fAliplayer.setVidAuth(
            vid: _dataSourceMap[DataSourceRelated.VID_KEY],
            region: _dataSourceMap[DataSourceRelated.REGION_KEY],
            playAuth: _dataSourceMap[DataSourceRelated.PLAYAUTH_KEY],
            definitionList: _dataSourceMap[DataSourceRelated.DEFINITION_LIST],
            previewTime: _dataSourceMap[DataSourceRelated.PREVIEWTIME_KEY]);
        break;
      default:
    }
  }

  ///可选步骤:开启自动播放，默认关闭
  fAliplayer.setAutoPlay(true);
  ///5、prepare
  fAliplayer.prepare();
  ///说明：如果开启了自动播放，则调用 prepare 后即可，播放器在 prepare 成功后会自动播放，如果未开启自动播放，则需要在 setOnPrepard() 准备成功回调中，调用 fAliplayer.play() 开始播放

//暂停播放
///暂停播放后，恢复播放直接调用 play 即可
fAliplayer.pause();

//停止播放
///停止播放后，恢复播放需要重新走一遍播放流程：prepare --> play
fAliplayer.stop();

//销毁
fAliplayer.release();

//seek
///seekMode 可选值：FlutterAvpdef.ACCURATE(精准seek) 和 FlutterAvpdef.INACCURATE(非精准seek)
fAliplayer.seek(position,seekMode);

//循环播放
fAliplayer.setLoop(true);

//静音、音量控制
fAliplayer.setMute(true);
///设置播放器音量,范围0~1.
fAliPlayer.setVolume(1);

//倍速播放
///可选值：0.5，1.0，1.5，2.0
fAliplayer.setRate(1.0);

//切换多码率，自动码率切换
///在prepare成功之后，通过getMediaInfo可以获取到各个码流的信息，即TrackInfo
fAliplayer.getMediaInfo().then((value) {
//value 为 map，value['tracks'] 可以获取对应的 TrackInfos 列表信息，可以参考 Demo 中 AVPMediaInfo info = AVPMediaInfo.fromJson(value); 如何解析 TrackInfo
};
///在播放过程中，可以通过调用播放器的selectTrack方法切换播放的码流,参数为 TrackInfo 中的 trackIndex，切换的结果会在OnTrackChangedListener监听之后会回调
fAliplayer.selectTrack(index);
  
///自动码率切换
fAliplayer.selectTrack(-1);

//画面旋转、填充、镜像操作
//设置画面的镜像模式：水平镜像，垂直镜像，无镜像。
fAliplayer.setMirrorMode(MirrorMode.MIRROR_MODE_NONE);
//设置画面旋转模式：旋转0度，90度，180度，270度
fAliplayer.setRotateMode(RotateMode.ROTATE_0);
//设置画面缩放模式：宽高比填充，宽高比适应，拉伸填充
fAliplayer.setScalingMode(ScaleMode.AVP_SCALINGMODE_SCALETOFILL);
```

### 2. 播放器其他配置

 需要在 prepare 之前设置给播放器

```dart
var configMap = {
  'mStartBufferDuration':_mStartBufferDurationController.text,///起播缓冲区时长
  'mHighBufferDuratio':_mHighBufferDurationController.text,///高缓冲时长
  'mMaxBufferDuration':_mMaxBufferDurationController.text,///最大缓冲区时长
  'mMaxDelayTime': _mMaxDelayTimeController.text,///最大延迟。注意：直播有效
  'mNetworkTimeout': _mNetworkTimeoutController.text,///网络超时时间
  'mNetworkRetryCount':_mNetworkRetryCountController.text,///网络重试次数
  'mMaxProbeSize': _mMaxProbeSizeController.text,///最大probe大小
  'mReferrer': _mReferrerController.text,///referrer
  'mHttpProxy': _mHttpProxyController.text,///http代理
  'mEnableSEI': mEnableSEI,///是否启用SEI
  'mClearFrameWhenStop': !mShowFrameWhenStop,///停止后是否清空画面
  'mDisableVideo': mDisableVideo,///禁用Video
  'mDisableAudio': mDisableAudio///禁用Audio
};
widget.fAliplayer.setConfig(configMap);
```

## AliListPlayer

```dart
//1.创建列表播放器
FlutterAliListPlayer fAliListPlayer = FlutterAliPlayerFactory.createAliListPlayer();

//2.添加资源、移除资源。列表播放器目前只支持两种播放方式，URL 和 STS    
///uid是视频的唯一标志。用于区分视频是否一样。如果uid一样，则认为是一样的
fAliListPlayer.addUrlSource(url,uid);
fAliListPlayer.addVidSource(vid,uid);
fAliListPlayer.removeSource(uid);

//设置预加载个数
fAliListPlayer.setPreloadCount(count);

//播放视频源
///uid 为必填项，如果是 URL 播放方式，只需要 uid 即可，如果是 STS 方式，则需要填写 STS 信息
fAliListPlayer.moveTo();
```

## AliLiveShiftPlayer

```dart
//创建直播时移播放器
FlutterAliLiveShiftPlayer _flutterAliLiveShiftPlayer = FlutterAliPlayerFactory.createAliLiveShiftPlayer();

//设置渲染 View
@override
  Widget build(BuildContext context) {
    var x = 0.0;
    var y = 0.0;
    Orientation orientation = MediaQuery.of(context).orientation;
    var width = MediaQuery.of(context).size.width;

    var height;
    if (orientation == Orientation.portrait) {
      height = width * 9.0 / 16.0;
    } else {
      height = MediaQuery.of(context).size.height;
    }
    AliPlayerView aliPlayerView = AliPlayerView(
        onCreated: onViewPlayerCreated,
        x: x,
        y: y,
        width: width,
        height: height);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin for LiveShiftPlayer'),
      ),
      body: Column(children: [
        Container(
          width: width,
          height: height,
          child: aliPlayerView,
        ),
      ]),
    );
  }

///setPlayerView(viewId) 给播放器设置渲染 View
///setDataSource(timelineUrl,url) 设置播放源，其中 url 为播放地址，timelineurl 为时移请求地址
void onViewPlayerCreated(int viewId) {
    this._flutterAliLiveShiftPlayer.setPlayerView(viewId);
    int time = (new DateTime.now().millisecondsSinceEpoch / 1000).round();
    var timeLineUrl =
        "$_timeLineUrl&lhs_start_unix_s_0=${time - 5 * 60}&lhs_end_unix_s_0=${time + 5 * 60}";
    _flutterAliLiveShiftPlayer.setDataSource(timeLineUrl, _url);
  }
}

///时移到某个时间
_flutterAliLiveShiftPlayer.seekToLiveTime();

///获取当前直播的播放时间
flutterAliLiveShiftPlayer.getCurrentTime().then((value) {});

///获取当前直播的现实时间
_flutterAliLiveShiftPlayer.getCurrentLiveTime().then((value) {});

///准备
_flutterAliLiveShiftPlayer.prepare();

///开始播放
_flutterAliLiveShiftPlayer.play();

///停止
_flutterAliLiveShiftPlayer?.stop();
///销毁
_flutterAliLiveShiftPlayer?.destroy();

///时移seek完成通知。playerTime:实际播放的时间
_flutterAliLiveShiftPlayer.setOnSeekLiveCompletion(playTime, playerId) {});

//时移时间更新监听事件。currentTime - 当前现实时间，shiftStartTime - 可时移的起始时间，shiftEndTime - 可时移的结束时间
_flutterAliLiveShiftPlayer.setOnTimeShiftUpdater((currentTime, shiftStartTime, shiftEndTime, playerId) {});
```



## 下载

  可选步骤,如果是安全下载，需要配置自己的加密校验文件到 SDK 中，普通下载则不需要

```dart
//配置加密校验文件，尽可能提前配置(可选)  
FlutterAliPlayerFactory.initService(byteData);

//创建下载器
FlutterAliDownloader donwloader = FlutterAliDownloader.init();
///设置保存路径
donwloader.setSaveDir(path)

//开始下载
///1.prepare
///参数说明：type 可选值为 FlutterAvpdef.DOWNLOADTYPE_STS / FlutterAvpdef.DOWNLOADTYPE_AUTH 。当 type 为 DOWNLOADTYPE_STS 时候，必填参数为： {vid,accessKeyId,accessKeySecret,securityToken}，当 type 为 DOWNLOADTYPE_AUTH 时，必须填参数为 {vid,playAuth}
  downloader.prepare(type, vid).then((value) {
      //value 为 map，对应 Demo 中的 DownloadModel 自定义下载类
      DownloadModel downloadModel = DownloadModel.fromJson(value);
      //2.selectItem，根据不同的 trackInfo 来确定需要下载哪个清晰度
      List<TrackInfoModel> trackInfos = downloadModel.trackInfos;
      downloader.selectItem(vid,trackInfos[0].index);
      //3.start
      downloader.start(vid, trackInfos[0].index).listen((event) {
        //说明：event 可能会有多种信息,可参考 FlutterAvpdef.EventChanneldef 中的信息，以下为具体说明：
        if (event[EventChanneldef.TYPE_KEY] == EventChanneldef.DOWNLOAD_PROGRESS){
            //下载进度百分比信息，获取下载进度百分比：event[EventChanneldef.DOWNLOAD_PROGRESS]
        }else if(event[EventChanneldef.TYPE_KEY] == EventChanneldef.DOWNLOAD_PROCESS){
            //处理进度百分比信息，获取处理进度百分比：event[EventChanneldef.DOWNLOAD_PROCESS]
        }else if(event[EventChanneldef.TYPE_KEY] == EventChanneldef.DOWNLOAD_COMPLETION){
            //下载完成，可以通过 event['vid']、event['index'] 获取对应的 vid 和 index 用于判断是哪个视频下载完成，event['savePath'] 用于获取下载完成视频的本地路径

            // 'savePath'在iOS中是相对路径，每次进行播放时可以通过调用getFullSaveForIOS('savePath')进行获取全路径，保证路径获取的正确性，安卓直接使用就可以
            if (Platform.isIOS) {
              donwloader.getFullSavePathForIOS(event['savePath']).then((value) {
                // value是最新的全路径，可以拿这个路径去播放
              });
            }
        }else if(event[EventChanneldef.TYPE_KEY] == EventChanneldef.DOWNLOAD_ERROR){
            //下载失败，可以通过 event['vid']、event['index'] 获取对应的 vid 和 index 用于判断是哪个视频下载失败，event['errorCode']、event['errorMsg'] 可以获取对应的错误码，和错误信息
        }
      });
  });

//停止下载、删除和释放
downloader.stop(vid, index)
//可以删除下载的本地文件
downloader.delete(vid, index)
downloader.release(vid, index)
```

## 加载 RtsSDK
如果需要支持 artc 协议，首先需要引入如下两个插件：
```yaml
//flutter_aliplayer_artc: 对应版本号
//flutter_aliplayer_rts: 对应版本号

```

Android 在build.gradle中添加依赖即可
```
dependencies{
    implementation 'com.aliyun.aio:AliVCSDK_InteractiveLive:$version'
}
```

iOS在Podfile文件中添加依赖即可
```
target 'Runner' do
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  pod 'AliVCSDK_InteractiveLive', '$version'

end
```


Android 需要额外调用如下代码(尽可能提前)：
```dart
FlutterAliPlayerFactory.loadRtsLibrary();
```
