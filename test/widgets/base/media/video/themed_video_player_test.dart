import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sakuramedia/widgets/base/media/video/player_screen_orientation.dart';
import 'package:sakuramedia/widgets/base/media/video/themed_video_player.dart';

import '../../../../support/test_playlist_player.dart';

class _FakeVideoController extends Fake implements VideoController {
  _FakeVideoController(this.player);

  @override
  final Player player;

  @override
  final notifier = ValueNotifier<PlatformVideoController?>(null);

  @override
  Future<void> get waitUntilFirstFrameRendered => Future.value();
}

void main() {
  Future<void> pumpPlayer(
    WidgetTester tester, {
    required bool useTouchOptimizedControls,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.alexmercerind/media_kit_video'),
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.alexmercerind/media_kit_video'),
        null,
      ),
    );
    final player = Player(platformPlayer: TestPlaylistPlayer());
    addTearDown(player.dispose);
    final controller = _FakeVideoController(player);
    addTearDown(controller.notifier.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ThemedVideoPlayer(
          videoController: controller,
          useTouchOptimizedControls: useTouchOptimizedControls,
        ),
      ),
    );
  }

  testWidgets('移动端全屏接管方向：进入跟随传感器、退出回页面横屏', (tester) async {
    await pumpPlayer(tester, useTouchOptimizedControls: true);

    final video = tester.widget<Video>(find.byType(Video));
    expect(video.onEnterFullscreen, enterPlayerFullscreenOrientation);
    expect(video.onExitFullscreen, lockPlayerPageLandscape);
  });

  testWidgets('桌面端保持 media_kit 默认全屏回调', (tester) async {
    await pumpPlayer(tester, useTouchOptimizedControls: false);

    final video = tester.widget<Video>(find.byType(Video));
    expect(video.onEnterFullscreen, defaultEnterNativeFullscreen);
    expect(video.onExitFullscreen, defaultExitNativeFullscreen);
  });
}
