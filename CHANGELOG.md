## 7.18.0

### 🚀 更新概览
- **内核升级**：播放器 SDK 升级至 **7.18.0** 版本（Android / iOS 原生依赖已同步更新）。
- **稳定性**：提升 HLS 字幕流出错场景的兼容性。
- **稳定性**：修复部分已知问题，提升播放器稳定性

---

## 7.16.0

### 🚀 更新概览
- **内核升级**：播放器 SDK 升级至 **7.16.0** 版本（Android / iOS 原生依赖已同步更新）。
- **新功能**：新增 iOS 画中画（Picture in Picture）控制能力，支持 `startPip` / `stopPip`。
- **新功能**：新增默认字幕语言设置 `setDefaultSubtitleLanguage` 与当前 VPS 信息获取 `getCurrentVps`，`AliPlayer` 与 `AliListPlayer` 均可使用。
- **稳定性**：优化 iOS 画中画生命周期，在 `destroy` / `releaseAsync` 时自动停止画中画并清理 `AVPictureInPictureController`；`AliPlayerProxy` dealloc 时释放 `pipController` 强引用，避免异常回调。

---

### ✨ 新增 API

#### 画中画控制（仅 iOS）

新增 `startPip` 与 `stopPip`，用于手动触发 / 关闭系统画中画窗口。

| 方法名 | 说明 | 平台 |
| :--- | :--- | :--- |
| `startPip` | 启动系统画中画 | iOS |
| `stopPip` | 关闭系统画中画 | iOS |

> ⚠️ **使用说明**
>
> *   调用 `startPip` 前，需要先通过 `setPictureInPictureEnableForIOS(true)` 开启播放器画中画能力，并确保播放器处于播放状态。
> *   `startPip` 依赖 `pipController` 已存在。该控制器通常在系统首次触发画中画（例如用户点击 Home 键 / 上滑进入后台）时，由 SDK 通过 `pictureInPictureControllerWillStartPictureInPicture:` 回调创建并赋值；如果尚未生成，直接调用 `startPip` 不会生效。
> *   `stopPip` 不会销毁播放器；释放播放器前建议先调用 `stopPip`，等待画中画窗口关闭后再调用 `release` / `destroy`。

```dart
// 开启画中画能力（建议在 onPrepared 后调用）
await player.setPictureInPictureEnableForIOS(true);

// 启动画中画
await player.startPip();

// 关闭画中画
await player.stopPip();
```

#### 默认字幕语言与 VPS

| 方法名 | 说明 | 参数 / 返回 |
| :--- | :--- | :--- |
| `setDefaultSubtitleLanguage` | 设置多码率播放时默认使用的字幕流 | `String language` |
| `getCurrentVps` | 获取当前播放使用的视频播放服务（VPS）信息 | 返回 `String`，可能为空 |

```dart
// 设置默认字幕语言
await player.setDefaultSubtitleLanguage("chi");

// 获取当前 VPS
String vps = await player.getCurrentVps();
```

---

### 🐛 修复与优化
- iOS：在 `destroy` 与 `releaseAsync` 时增加画中画清理逻辑，防止后台或释放时出现异常。
- iOS：`AliPlayerProxy` dealloc 时释放 `pipController` 强引用。

---

## 7.15.0

### 🚀 更新概览
- **内核升级**：播放器 SDK 升级至 **7.15.0** 版本。

---

## 7.14.0

### 🚀 更新概览
- **内核升级**：播放器 SDK 升级至 **7.14.0** 版本。
- **新功能**：新增系统亮度控制 API (`set/getSystemBrightness`)。
- **稳定性**：修复若干已知问题，提升播放稳定性。

### ✨ 新增 API：系统亮度控制

新增 `setSystemBrightness` 和 `getSystemBrightness`接口，用于管理屏幕亮度。

| 方法名 | 说明 | 参数/返回 |
| :--- | :--- | :--- |
| `setSystemBrightness` | 设置系统/应用亮度 | `double` (范围: `0.0` ~ `1.0`) |
| `getSystemBrightness` | 获取当前亮度值 | 返回 `double` |

> ⚠️ **平台行为差异说明**
>
> *   **Android**：表现为**应用内亮度**。仅在应用前台运行时生效，退出应用或切换后台后，系统亮度将自动还原。
> *   **iOS**：表现为**系统全局亮度**。修改后将直接影响系统亮度设置，且**不会**在退出应用后自动还原，需开发者自行管理恢复逻辑。

---

## 7.12.0

### 🚀 更新改动
- 播放器 SDK 升级到 **7.12.0**
- 修复了 removeSource 移除失败的 bug
- 修复了 同时创建多个不同类型的 player 时出现的 API 调用异常
- 新增 ListPlayer 相关API 及 部分播放器通用API

### ✨ 新增功能

#### 新增 API 

**AliPlayer 使用示例**

> **setDefaultResolution**: 设置多码率播放时的默认起播清晰度
> **setDefaultBandWidth**: 设置多码率播放时的默认起播码率

```dart
// 创建单实例播放
FlutterAliplayer fAliplayer = FlutterAliPlayerFactory.createAliPlayer();
// 设置默认起播清晰度
fAliplayer.setDefaultResolution(1920 * 1080);
// 设置默认起播码率
fAliplayer.setDefaultBandWidth(200000);
```

**ListPlayer 使用示例**
```dart
// 创建列表播放器
FlutterAliListPlayer fAliListPlayer = FlutterAliPlayerFactory.createAliListPlayer(playerId: 'aliListPlayer');
// 设置默认起播清晰度
fAliListPlayer.setDefaultResolution(1920 * 1080);
// 设置默认起播码率
fAliListPlayer.setDefaultBandWidth(200000);
// 配置基准预加载时长 单位为 ms
fAliListPlayer.updatePreloadConfig(1500);
// 配置动态预加载的递减的offset
fAliListPlayer.enablePreloadStrategy(true);
fAliListPlayer.setPreloadStrategy("{\"algorithm\": \"sub\",\"offset\": \"200\"}");
```

**setPlayerScene**

> **说明**: 设置播放器场景，AliPlayer/ListPlayer 可以通用。播放器会根据场景修改播放设置，播放更流畅丝滑。

```dart
/// 播放场景
enum PlayerScene {
  NONE,
  LONG, // 长视频
  MEDIUM,   // 中视频
  SHORT,    // 短视频
  LIVE,     // 直播
  RTS_LIVE, // RTS 拉流
}

// 设置长视频场景
fAliplayer.setPlayerScene(PlayerScene.LONG);
// 设置短视频场景
fAliListPlayer.setPlayerScene(PlayerScene.SHORT);
```

**setPreloadScene**

> **说明**: 设置预加载模式，在 listPlayer + 多码率HLS视频播放场景下，支持集成方预加载与当前播放清晰度一致的流，并且可以根据业务情况选择预加载模式。

```dart
/// 预加载场景
enum PreloadScene {
  SCENE_NONE, // 默认
  SCENE_VERY_SHORT, // 极短视频
  SCENE_SHORT,  // 短视频
  SCENE_MIDDLE,  // 中视频
  SCENE_LONG, // 长视频
}

fAliListPlayer.setPreloadScene(PreloadScene.SCENE_SHORT);
```

---

## 7.11.0

---

### 🚀 更新 Native SDK
- 播放器 SDK 升级到 **7.11.0**
- RTS SDK 升级到 **7.12.0**

### ✨ 新增功能

#### Android 支持 `AliDisplayView` 选项

> **说明**：HDR 视频在 Android 端需使用 `AliDisplayView` 实现画面旋转、填充模式及镜像效果。

**使用示例**：
```dart
AliPlayerView(
  onCreated: onViewPlayerCreated,
  x: x,
  y: y,
  width: width,
  height: height,
  aliPlayerViewType: AliPlayerViewTypeForAndroid.displayview,
);
```

#### 自动刷新数据源
>说明：启用播放源自动刷新功能可防止因鉴权过期导致的播放中断。当播放源失效时，会触发回调以获取新的有效地址，确保视频持续流畅播放。
>功能限制：仅支持 VidAuth 和配置了鉴权机制的视频 URL。

URL 源过期回调 (OnURLSourceExpiredCallBack)：

```dart
fAliplayer.setOnURLSourceExpiredListener(
  call: (String? expiredUrl) async {
    print('the expiredUrl is $expiredUrl');
    return 'your Video URL'; // 返回新 URL，或返回 null 表示放弃刷新
  },
);
```

VidAuth 过期回调 (OnAuthSourceExpiredCallBack)：

```dart
fAliplayer.setOnVidAuthExpiredListener(
  call: (VidAuth? vidAuth) async {
      return VidAuth(
          vid: "your videoId",
          playAuth: "your playAuth",
      );
    },
);
```


## 7.10.0

---

升级 Native 播放器SDK 到 7.10.0

## 7.9.0

---

**🚀 更新 Native SDK 到 7.9.1**

**✨ 新增功能**

**FlutterAliMediaLoaderV2 预加载模块**

全面支持多种数据源预加载：

- ✅ URL 源：直接通过视频 URL 进行预加载
- ✅ VidAuth 源：支持阿里云视频点播标准鉴权方式（VID + PlayAuth）
- ✅ VidSts 源：支持 STS 临时令牌鉴权方式（VID + AccessKey + SecurityToken）
  统一预加载接口：通过单一 API 管理所有类型视频源的预加载任务

任务管理能力：支持任务添加、状态监听、资源释放等完整生命周期管理

**示例**

1、创建 FlutterAliMediaLoaderV2 实例

```dart
 FlutterAliMediaLoaderV2 loaderV2 = FlutterAliMediaLoaderV2();
```

2、设置监听

* `onError` 异常监听

```dart
loaderV2.onError = (ErrorInfo error) {
   print("MediaLoaderV2 Code:${error.errorCode}, Msg:${error.errorMsg} Extra: ${error.errorExtra}");
};
```

* `onCompleted` 任务完成监听

```dart
loaderV2.onCompleted = (taskId, urlOrVid) {
  
};
```

* `onCanceled` 任务取消监听

```dart
loaderV2.onCanceled = (taskId, urlOrVid) {
   
};
```

3、`setPreloadConfig`  设置预加载任务参数

仅适用于多码率视频， `defaultBandWidth`、`defaultResolution`、`defaultQuality`三者任选其一即可。

```dart
PreloadConfig config = PreloadConfig();
config.duration = 1000;  // 默认为 1000
config.defaultQuality = "FD";
config.defaultBandWidth = 200000;
config.defaultResolution  = 1920 * 1080;
loaderV2.setPreloadConfig(config);
```

4、`addTask` 添加任务并获取 `taskId`

- UrlSource

```dart
loaderV2.addTask(UrlSource(videoUrl: "videoUrl")).then((taskId) {
   print("MediaLoaderV2: taskId: $taskId");
});
```

- VidAuth

```dart
VidAuth auth = VidAuth(
   vid: "your videoId",
   playAuth: "your playAuth",
   region: "your region",
);
loaderV2.addTask(auth).then((taskId) {
    print("MediaLoaderV2: taskId: $taskId");
});
```

- VidSts

```dart
VidSts vidSts = VidSts(
    vid: "your vid",
    accessKeyId: "your accessKeyId",
    accessKeySecret: "your accessKeySecret",
    securityToken: "your securityToken",
);
loaderV2.addTask(vidSts).then((taskId) {
   print("MediaLoaderV2: taskId: $taskId");
});

```

5、`pauseTask(taskId)` 暂停任务

```dart
loaderV2.pauseTask(taskId);
```

6、`resumeTask(taskId)` 恢复任务

```dart
loaderV2.resumeTask(taskId);
```

7、`cancelTask(taskId)` 取消任务

```dart
loaderV2.cancelTask(taskId);
```

8、`dispose` 销毁MedialoaderV2

```dart
loaderV2.dispose();
```

**🗑️ API 废弃与删除**

|        API 方法        |    替代方案    |                   说明                   |
| :---------------------: | :------------: | :---------------------------------------: |
|      `destroy()`      | `release()` |   播放器销毁逻辑已统一至 `release()`   |
|      `setRate()`      | `setSpeed()` | 播放速率设置功能已经统一至 `setSpeed()` |
|  `getCacheConfig()`  |       -       |        过时方法，请清除相关API调用        |
| `setCacheConfig(Map)` |       -       |        过时方法，请清除相关API调用        |

**🗑️ 常量 删除**

|           常量           |    替代方案    |          说明          |
| :-----------------------: | :------------: | :---------------------: |
| `AVP_SCALINGMODE_XXXXX` | `ScaleMode` | 统一使用 `ScaleMode` |
|    `AVP_ROTATE_XXXX`    | `RotateMode` | 统一使用 `RotateMode` |
|  `AVP_MIRRORMODE_XXXX`  | `MirrorMode` | 统一使用 `MirrorMode` |

**🔁 重命名的 API**
为提升语义准确性，以下方法已重命名

getRate  => getSpeed

```dart
// ❌ 旧用法（已失效）
double rate = await player.getRate();

// ✅ 新用法
double speed = await player.getSpeed();
```

## 7.8.0

---

1. 升级 播放器SDK 到 7.8.0
2. 新增 DownloadEvent 、AliMediaInfo、AliTrackInfo

## 7.4.0

---

1. 修复 setScaleMode 枚举错误问题
2. 升级 播放器SDK 到 7.4.0

## 7.3.0

---

1. 升级播放器SDK 到7.3.0
2. 升级RtsSDK（超低延迟组件）到 7.3.0

## 7.2.1

---

1. 增加 setLogInfoCallBack SDK 日志回调方法
2. 增加 getLogLevel 对 iOS 的方法支持
3. 移除 registerWith 方法，修复因 registerWith() 导致的 Android端 无法编译的问题

## 7.2.0

---

1. 更新 播放器SDK 内核 至 7.2.0
2. 更新 一体化SDK 内核 至 7.1.0

## 7.1.0

---

1. 更新 RTS 低延迟直播组件 内核 至 7.2.0
2. 更新 播放器 SDK 内核 至 7.1.0

## 7.0.0

---

1. 更新 SDK 内核 至 7.0.0
2. 新增 onSubTrackReady 监听
3. 修复一些Bug

## 6.19.0

---

1. 更新 Native SDK 至 6.19.0
2. 新增ios画中画状态监听及按钮透出
3. 增加abr升路上限功能
4. 修复部分已知问题

## 6.18.0

---

1. 更新 Native SDK 至 6.18.0
2. 新增预渲染功能
3. 修复部分已知问题，加快首帧渲染显示

## 6.17.0

---

1. 更新 Native SDK 至 6.17.0，使用独立SDK（AliPlayerSDK）代替一体化SDK（AliVCSDK_InteractiveLive），提供useAIOFramework开关支持SDK内核切换

## 6.7.0

---

1. 更新 Native SDK 至 6.7.0
2. 解决与推流插件 flutter_livepush_plugin 冲突问题，使用一体化SDK（AliVCSDK_InteractiveLive）代替独立SDK（AliPlayerSDK）

## 5.5.6

---

1. 更新播放器 SDK 至 5.5.6.0，并增加对应 SDK 接口
2. Demo 增加水印，打点，缩略图，画中画等功能

## 5.4.10

---

1. 修复 Android 创建 ListPlayer 出现错误日志问题
2. 修复 Android 调用截图接口，在图片未完全保存到本地时，回调截图成功问题
3. iOS 增加接口，用于下载后获取全路径
4. AliPlayerView 增加 aliPlayerViewType 属性，用于指定渲染 View 的类型(仅对 Android 有效)
5. Android 适配低版本 SDK 运行报错问题
6. iOS 修改为本地集成播放器原生SDK

## 5.4.9-dev.1.3

---

1. iOS 修改为本地集成播放器原生SDK

## 5.4.9-dev.1.2

---

1. Android 适配低版本 SDK 运行报错问题

## 5.4.9-dev.1.1

---

1. AliPlayerView 增加 aliPlayerViewType 属性，用于指定渲染 View 的类型(仅对 Android 有效)

## 5.4.9-dev.1.0

---

1. 修复 Android 创建 ListPlayer 出现错误日志问题
2. 修复 Android 调用截图接口，在图片未完全保存到本地时，回调截图成功问题
3. iOS 增加接口，用于下载后获取全路径

## 5.4.9

---

1. 更新播放器 SDK(更新 OpenSSL)
2. 修复 Android 播放 hdr 视频问题
3. 修复 Android、iOS 部分接口调用报错问题

## 5.4.8-dev.1.2

---

1. 修复 Android 播放报错问题
2. 修复 iOS 播放时，偶现 onInfo 没有回调的问题
3. flutter 接口增加空类型支持

## 5.4.8-dev.1.0

---

1. 更新 Anddroid、iOS播放器SDK为 5.4.8.0
2. 移除 flutter_aliplayer_artc 和 flutter_rts，需要使用 Rts SDK，请自行在 Android、iOS 项目里添加依赖
3. 新增接口

## 5.4.3-dev.5

---

1. 增加 Sei 、SubtitleHeader 接口调用
2. 增加 FlutterAliPlayerFactory.loadRtsLibrary() 接口，(Android)
3. 修复 5.4.2 编译报错问题
4. 修复集成 Rts 低延时直播无法播放问题
5. 修复 AliPlayer、AliListPlayer、AliLiveShiftPlayer 依次创建后，先创建的对象失效问题

## 5.4.2

---

阿里云播放器版本更新至：5.4.2.0
flutter_aliplayer_artc : ^5.4.2
flutter_rts : ^1.9.0

1. 增加直播时移功能(测试中)
2. 修复下载无法设置 region 问题
3. 重复创建 AliPlayer 对象，导致先创建的 AliPlayer 对象回调监听失效问题

## 5.4.0

---

阿里云播放器版本更新至：5.4.0
flutter_aliplayer_artc : ^5.4.0
flutter_rts : ^1.6.0

1. 支持多个播放实例，具体可以参照demo代码 `multiple_player_page.dart`
2. 播放器回调添加playerId参数，用于多实例调用的区分
3. 添加 `setPlayerView`方法，创建播放器后，需要绑定view到播发器
4. 去除原列表播放器管道，在android和iOS源码层AliListPlayer与AliPlayer公用一个管道
5. `initService`、`getSDKVersion`以及log级别开关等方法改为静态方法，与原生sdk对齐

## 5.2.2

---

1. Docking Aliyun Player SDK (PlatForm include Android、iOS)
2. RenderView: Android uses TextureView,iOS uses UIView
