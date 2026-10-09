import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sakuramedia/widgets/base/media/video/player_app_fullscreen.dart';
import 'package:sakuramedia/widgets/base/media/video/video_controls_theme.dart';

class _FullscreenHarness extends StatefulWidget {
  const _FullscreenHarness({this.useDoubleTap = false});

  final bool useDoubleTap;

  @override
  State<_FullscreenHarness> createState() => _FullscreenHarnessState();
}

class _FullscreenHarnessState extends State<_FullscreenHarness>
    with PlayerAppFullscreenStateMixin<_FullscreenHarness> {
  // 单测不碰窗口通道，只验布局态。
  @override
  bool get applySystemFullscreenForAppFullscreen => false;

  @override
  Widget build(BuildContext context) {
    return PlayerAppFullscreenScope(
      isFullscreen: isAppFullscreen,
      onToggle: toggleAppFullscreen,
      child: PlayerAppFullscreenDoubleTap(
        enabled: widget.useDoubleTap,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PlayerAppFullscreenButton(),
            Text('video-area'),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  bool useDoubleTap = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: _FullscreenHarness(useDoubleTap: useDoubleTap)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PlayerAppFullscreenButton', () {
    testWidgets('falls back to media_kit fullscreen without scope', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlayerAppFullscreenButton()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialFullscreenButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggles app fullscreen and swaps icon', (
      WidgetTester tester,
    ) async {
      await _pumpHarness(tester);

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_exit), findsNothing);

      await tester.tap(find.byType(PlayerAppFullscreenButton));
      await tester.pumpAndSettle();

      // 右侧面板仍在同一路由内：scope 只是切布局态，不 push 全屏路由。
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('touch variant renders mobile custom button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerAppFullscreenScope(
              isFullscreen: false,
              onToggle: () {},
              child: const PlayerAppFullscreenButton(
                useTouchOptimizedControls: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialCustomButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('escape exits app fullscreen', (
      WidgetTester tester,
    ) async {
      await _pumpHarness(tester);
      await tester.tap(find.byType(PlayerAppFullscreenButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('double tap toggles only when enabled', (
      WidgetTester tester,
    ) async {
      Future<void> doubleTapVideoArea() async {
        await tester.tap(find.text('video-area'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('video-area'));
        await tester.pumpAndSettle();
      }

      await _pumpHarness(tester);
      await doubleTapVideoArea();
      // 未启用双击：状态不变。
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      await _pumpHarness(tester, useDoubleTap: true);
      await doubleTapVideoArea();
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('native fullscreen opt-out', () {
    test('desktop double-press fullscreen stays on by default', () {
      final themeData = buildMoviePlayerDesktopControlsThemeData(
        theme: ThemeData.light(),
        topControls: const <Widget>[],
        bottomControls: const <Widget>[],
      );

      expect(themeData.toggleFullscreenOnDoublePress, isTrue);
    });

    test('panel pages can disable desktop double-press fullscreen', () {
      final themeData = buildMoviePlayerDesktopControlsThemeData(
        theme: ThemeData.light(),
        topControls: const <Widget>[],
        bottomControls: const <Widget>[],
        toggleFullscreenOnDoublePress: false,
      );

      expect(themeData.toggleFullscreenOnDoublePress, isFalse);
    });
  });
}
