import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_quality_comparison_overlay.dart';

/// 1x1 透明 PNG，仅用于让 `Image.memory` 有可解码的数据。
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required VoidCallback onCompleted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: sakuraThemeData,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox(
          width: 800,
          height: 450,
          child: MoviePlayerQualityComparisonOverlay(
            originalFrame: _tinyPng,
            onCompleted: onCompleted,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('MoviePlayerQualityComparisonOverlay', () {
    testWidgets('divider sweeps, holds in the middle, then finishes', (
      tester,
    ) async {
      await _pumpOverlay(tester, onCompleted: () {});

      final divider = find.byKey(
        const Key('movie-player-quality-comparison-divider'),
      );
      expect(divider, findsOneWidget);
      expect(
        find.byKey(const Key('movie-player-quality-comparison-original')),
        findsOneWidget,
      );

      // 标签与分割线在动画最开头淡入，先推进一步再取起点。
      await tester.pump(const Duration(milliseconds: 300));
      final startX = tester.getTopLeft(divider).dx;
      expect(
        find.byKey(
          const Key('movie-player-quality-comparison-enhanced-label'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movie-player-quality-comparison-original-label')),
        findsOneWidget,
      );

      // 第一段 600ms 后停在中间，并在整个 1.5s 停顿期间保持不动。
      await tester.pump(const Duration(milliseconds: 300));
      final holdStartX = tester.getTopLeft(divider).dx;
      await tester.pump(const Duration(milliseconds: 700));
      final holdMiddleX = tester.getTopLeft(divider).dx;
      await tester.pump(const Duration(milliseconds: 700));
      final holdEndX = tester.getTopLeft(divider).dx;

      expect(holdStartX, greaterThan(startX));
      expect(holdStartX, closeTo(400, 2));
      expect(holdMiddleX, closeTo(400, 2));
      expect(holdEndX, closeTo(400, 2));
      expect(
        find.byKey(
          const Key('movie-player-quality-comparison-enhanced-label'),
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 700));
      final endX = tester.getTopLeft(divider).dx;
      expect(endX, greaterThan(holdEndX));
      expect(endX, closeTo(800, 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports completion once the sweep is done', (tester) async {
      var completed = 0;
      await _pumpOverlay(tester, onCompleted: () => completed++);

      await tester.pump(const Duration(milliseconds: 2600));
      expect(completed, 0);

      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
