import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/glass/app_glass_surface.dart';
import 'package:sakuramedia/widgets/base/layout/glass/app_media_badge.dart';

void main() {
  testWidgets('renders label and leading on a glass badge surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: AppMediaBadge(
            label: '42',
            leading: Icon(Icons.local_fire_department_rounded),
          ),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    final surface = tester.widget<AppGlassSurface>(
      find.byType(AppGlassSurface),
    );
    expect(surface.tone, AppGlassTone.badge);
  });

  testWidgets('fixed width and height include the glass rim', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: AppMediaBadge(label: '4K', width: 48, height: 24),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppMediaBadge));
    expect(size.width, 48);
    expect(size.height, 24);
  });

  testWidgets('fixed-size prominent label is not ellipsized', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: AppMediaBadge(
            label: '4K',
            width: 32,
            height: 24,
            padding: EdgeInsets.zero,
            size: AppMediaBadgeSize.prominent,
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('4K'));
    expect(paragraph.didExceedMaxLines, isFalse);
  });
}
