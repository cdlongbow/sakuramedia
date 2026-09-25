import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/widgets/base/media/video/player_screen_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  MethodCall callFor(String method) =>
      calls.singleWhere((call) => call.method == method);

  test('进入全屏跟随系统传感器并保持沉浸', () async {
    await enterPlayerFullscreenOrientation();

    expect(callFor('SystemChrome.setPreferredOrientations').arguments, <String>[
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(
      callFor('SystemChrome.setEnabledSystemUIMode').arguments,
      'SystemUiMode.immersiveSticky',
    );
  });

  test('播放页锁横屏（userLandscape）并保持沉浸', () async {
    await lockPlayerPageLandscape();

    expect(callFor('SystemChrome.setPreferredOrientations').arguments, <String>[
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(
      callFor('SystemChrome.setEnabledSystemUIMode').arguments,
      'SystemUiMode.immersiveSticky',
    );
  });
}
