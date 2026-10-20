import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_demand/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel factoryChannel =
      MethodChannel('plugins.flutter_aliplayer_factory');
  const MethodChannel eventChannel = MethodChannel('flutter_aliplayer_event');
  final List<MethodCall> calls = <MethodCall>[];
  Completer<void>? viewBinding;
  Completer<int>? durationResult;

  setUp(() {
    calls.clear();
    viewBinding = null;
    durationResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(factoryChannel, (MethodCall call) async {
      calls.add(call);
      if (call.method == 'setPlayerView' && viewBinding != null) {
        await viewBinding!.future;
      }
      if (call.method == 'getDuration') {
        return durationResult == null ? 46000 : await durationResult!.future;
      }
      if (call.method == 'getCurrentPosition') {
        return 1000;
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, (MethodCall call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views,
            (MethodCall call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(factoryChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
    FlutterAliPlayerFactory.instanceMap.clear();
  });

  Future<void> sendEvent(String method, [Map<String, Object?>? extra]) async {
    final String id = FlutterAliPlayerFactory.instanceMap.keys.single;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'flutter_aliplayer_event',
      const StandardMethodCodec().encodeSuccessEnvelope(
        <String, Object?>{'method': method, 'playerId': id, ...?extra},
      ),
      (_) {},
    );
  }

  Future<void> openVideo(WidgetTester tester) async {
    await tester.pumpWidget(const VideoDemandDemoApp());
    await tester.tap(find.text('无主灯卧室，越住越喜欢'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  test('demo 数据源是合法的 https 地址', () {
    expect(Uri.tryParse(kDemoVideoUrl)?.scheme, 'https');
  });

  test('Android 正式包声明网络权限', () {
    final String manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('createAliPlayer 注册播放器实例', () {
    final FlutterAliplayer player = FlutterAliPlayerFactory.createAliPlayer();
    expect(
      FlutterAliPlayerFactory.instanceMap[player.playerId],
      same(player),
    );
  });

  testWidgets('首页是双列封面列表，不创建播放器', (WidgetTester tester) async {
    await tester.pumpWidget(const VideoDemandDemoApp());
    expect(find.byType(GridView), findsOneWidget);
    final GridView grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
    expect(find.byType(AliPlayerView), findsNothing);
    expect(FlutterAliPlayerFactory.instanceMap, isEmpty);
    expect(calls.where((call) => call.method == 'createAliPlayer'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击进入详情，绑定后准备并播放，返回释放播放器',
      (WidgetTester tester) async {
    await openVideo(tester);
    expect(find.byType(AliPlayerView), findsOneWidget);
    final List<String> methods = calls.map((call) => call.method).toList();
    expect(methods.indexOf('setPlayerView'), lessThan(methods.indexOf('setUrl')));
    expect(methods.indexOf('setUrl'), lessThan(methods.indexOf('prepare')));
    expect(methods, isNot(contains('play')));
    await sendEvent('onPrepared');
    await tester.pump();
    expect(calls.lastWhere((call) => call.method == 'play').method, 'play');
    expect(find.byTooltip('暂停'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(FlutterAliPlayerFactory.instanceMap, isEmpty);
    expect(calls.map((call) => call.method), containsAllInOrder(['stop', 'destroy']));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('播放失败可重试，准备完成前禁止播放和拖动',
      (WidgetTester tester) async {
    await openVideo(tester);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    await sendEvent('onError', <String, Object?>{
      'errorCode': 500,
      'errorMsg': 'network error',
    });
    await tester.pump();
    expect(find.textContaining('network error'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(calls.where((call) => call.method == 'prepare'), hasLength(2));
    await sendEvent('onPrepared');
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('播放结束后从头重播，切后台暂停且前台不自动恢复',
      (WidgetTester tester) async {
    await openVideo(tester);
    await sendEvent('onPrepared');
    await tester.pump();
    await sendEvent('onCompletion');
    await tester.pump();
    await tester.tap(find.byTooltip('重播'));
    await tester.pump();
    final MethodCall seek = calls.lastWhere((call) => call.method == 'seekTo');
    expect((seek.arguments['arg'] as Map)['position'], 0);
    expect(find.byTooltip('暂停'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(calls.map((call) => call.method), contains('pause'));
    final int playCount = calls.where((call) => call.method == 'play').length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls.where((call) => call.method == 'play'), hasLength(playCount));
    expect(find.byTooltip('播放'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('视图绑定期间返回不会继续准备播放', (WidgetTester tester) async {
    viewBinding = Completer<void>();
    await openVideo(tester);
    expect(calls.map((call) => call.method), contains('setPlayerView'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    viewBinding!.complete();
    await tester.pump();
    expect(calls.where((call) => call.method == 'prepare'), isEmpty);
    expect(FlutterAliPlayerFactory.instanceMap, isEmpty);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('准备完成前切到后台，回前台后仍需手动播放',
      (WidgetTester tester) async {
    await openVideo(tester);
    durationResult = Completer<int>();
    await sendEvent('onPrepared');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    durationResult!.complete(46000);
    await tester.pump();
    expect(calls.where((call) => call.method == 'play'), isEmpty);
    await tester.tap(find.byTooltip('播放'));
    await tester.pump();
    expect(calls.where((call) => call.method == 'play'), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('准备回调期间返回不再播放，拖动进度使用毫秒',
      (WidgetTester tester) async {
    await openVideo(tester);
    await sendEvent('onPrepared');
    await tester.pump();
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(12000);
    slider.onChanged!(12000);
    slider.onChangeEnd!(12000);
    await tester.pump();
    final MethodCall seek = calls.lastWhere((call) => call.method == 'seekTo');
    expect((seek.arguments['arg'] as Map)['position'], 12000);
    durationResult = Completer<int>();
    await sendEvent('onPrepared');
    final int playCount = calls.where((call) => call.method == 'play').length;
    await tester.pageBack();
    await tester.pumpAndSettle();
    durationResult!.complete(46000);
    await tester.pump();
    expect(calls.where((call) => call.method == 'play'), hasLength(playCount));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('返回列表保留滚动位置，窄屏大字体不溢出',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const VideoDemandDemoApp());
    await tester.drag(find.byType(GridView), const Offset(0, -250));
    await tester.pumpAndSettle();
    final ScrollableState scroll = tester.state<ScrollableState>(
      find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    final double offset = scroll.position.pixels;
    expect(offset, greaterThan(0));
    final Finder card = find.byType(InkWell).hitTestable().first;
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, offset);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
