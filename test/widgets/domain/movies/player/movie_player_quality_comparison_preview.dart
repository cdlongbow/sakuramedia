import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/player/movie_player_subtitle_state.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_mobile_drawers.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_quality_button.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_quality_comparison_overlay.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_speed_button.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_subtitle_button.dart';

const _previewDirectory =
    '/var/folders/bt/ggg86sts06x3zsj9g778m6q00000gn/T/opencode/'
    'quality-comparison-preview';

void main() {
  setUpAll(_loadPreviewFonts);

  testWidgets('captures the quality comparison wipe at mid sweep', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final frameBytes = (await tester.runAsync(_buildOriginalFrameBytes))!;

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData.copyWith(
            platform: TargetPlatform.macOS,
            textTheme: sakuraThemeData.textTheme.apply(
              fontFamily: 'PreviewCjk',
            ),
            primaryTextTheme: sakuraThemeData.primaryTextTheme.apply(
              fontFamily: 'PreviewCjk',
            ),
          ),
          home: Scaffold(
            backgroundColor: Colors.black,
            body: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 1100,
                height: 620,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 模拟开启增强后的实时画面：平滑渐变 + 细亮线。
                    const CustomPaint(painter: _EnhancedSurfacePainter()),
                    MoviePlayerQualityComparisonOverlay(
                      originalFrame: frameBytes,
                      onCompleted: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // 让 Image.memory 完成解码，再推进到第一段扫过的中段。
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await capturePreview(
        tester,
        boundaryKey,
        '$_previewDirectory/quality-comparison-sweep-1100x620.png',
      );

      // 中间停顿的 1.5 秒：分割线停在正中，标签仍可见。
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);
      await capturePreview(
        tester,
        boundaryKey,
        '$_previewDirectory/quality-comparison-hold-1100x620.png',
      );

      // 末段：标签已淡出，分割线扫到右缘。
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);
      await capturePreview(
        tester,
        boundaryKey,
        '$_previewDirectory/quality-comparison-late-1100x620.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures the quality toggle next to existing controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(680, 90);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final subtitleState = ValueNotifier<MoviePlayerSubtitleState>(
      MoviePlayerSubtitleState.empty,
    );
    final isApplying = ValueNotifier<bool>(false);
    final speedDisplay = ValueNotifier<MoviePlayerMobileSpeedDisplayState>(
      const MoviePlayerMobileSpeedDisplayState(
        rate: 1.0,
        hasExplicitSelection: false,
      ),
    );
    final qualityOff = ValueNotifier<bool>(false);
    final qualityOn = ValueNotifier<bool>(true);
    addTearDown(subtitleState.dispose);
    addTearDown(isApplying.dispose);
    addTearDown(speedDisplay.dispose);
    addTearDown(qualityOff.dispose);
    addTearDown(qualityOn.dispose);

    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData.copyWith(
            platform: TargetPlatform.macOS,
            textTheme: sakuraThemeData.textTheme.apply(
              fontFamily: 'PreviewCjk',
            ),
            primaryTextTheme: sakuraThemeData.primaryTextTheme.apply(
              fontFamily: 'PreviewCjk',
            ),
          ),
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: ColoredBox(
                  color: Colors.black,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoviePlayerSpeedButton(
                        currentRate: 1.0,
                        hasExplicitSelection: false,
                        onRateSelected: (_) async {},
                      ),
                      MoviePlayerSubtitleButton(
                        subtitleStateListenable: subtitleState,
                        isApplyingListenable: isApplying,
                        onSubtitleSelected: (_) async {},
                        onReloadRequested: () async {},
                      ),
                      MoviePlayerQualityButton(
                        label: '画质增强',
                        enabledListenable: qualityOff,
                        onPressed: () {},
                      ),
                      MoviePlayerQualityButton(
                        label: '画质增强',
                        enabledListenable: qualityOn,
                        onPressed: () {},
                      ),
                      // 移动端形态：只放开关本体。
                      MoviePlayerQualityButton(
                        enabledListenable: qualityOff,
                        onPressed: () {},
                      ),
                      MoviePlayerQualityButton(
                        enabledListenable: qualityOn,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePreview(
        tester,
        boundaryKey,
        '$_previewDirectory/quality-button-row-680x90.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// 生成一张"未增强"的原始帧：渐变分档明显（模拟色带）。
Future<Uint8List> _buildOriginalFrameBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const width = 1920.0;
  const height = 1080.0;
  const steps = 14;
  for (var index = 0; index < steps; index++) {
    final t = index / (steps - 1);
    final color = Color.lerp(
      const Color(0xFF0B1020),
      const Color(0xFF4A5568),
      t,
    )!;
    canvas.drawRect(
      Rect.fromLTWH(0, height * index / steps, width, height / steps + 1),
      Paint()..color = color,
    );
  }
  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
  }
}

/// 模拟开启增强后的实时画面：平滑渐变 + 更锐的细线。
class _EnhancedSurfacePainter extends CustomPainter {
  const _EnhancedSurfacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0B1020), Color(0xFF4A5568)],
        ).createShader(rect),
    );
    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.85)
      ..strokeWidth = 1.4;
    for (var index = 0; index < 26; index++) {
      final y = size.height * (index + 1) / 27;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 6), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _loadPreviewFonts() async {
  final cjkFont = FontLoader('PreviewCjk');
  final cjkBytes = await File(
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
  ).readAsBytes();
  cjkFont.addFont(Future<ByteData>.value(ByteData.sublistView(cjkBytes)));
  await cjkFont.load();

  final iconFont = FontLoader('MaterialIcons');
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    throw StateError('FLUTTER_ROOT is required to load MaterialIcons');
  }
  final iconBytes = await File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  iconFont.addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes)));
  await iconFont.load();
}

Future<void> capturePreview(
  WidgetTester tester,
  GlobalKey key,
  String outputPath,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}
