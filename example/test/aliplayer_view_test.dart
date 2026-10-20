import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('iOS creates a UIKit player view without OHOS-only getters',
      (WidgetTester tester) async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views,
            (MethodCall call) async => null);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 180,
          child: AliPlayerView(
            onCreated: null,
            x: 0,
            y: 0,
            width: 320,
            height: 180,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(UiKitView), findsOneWidget);
    expect(
      tester.widget<UiKitView>(find.byType(UiKitView)).viewType,
      'plugins.flutter_aliplayer',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
