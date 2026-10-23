import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/glass/app_glass_surface.dart';

void main() {
  Widget buildSurface({
    AppGlassTone tone = AppGlassTone.control,
    bool blur = true,
    bool highContrast = false,
    double? width,
    double? height,
  }) {
    return MaterialApp(
      theme: sakuraThemeData,
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: Scaffold(
          body: Center(
            child: AppGlassSurface(
              tone: tone,
              blur: blur,
              width: width,
              height: height,
              child: const SizedBox(
                key: Key('glass-child'),
                width: 60,
                height: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('builds every tone and renders the backdrop filter', (
    WidgetTester tester,
  ) async {
    for (final tone in AppGlassTone.values) {
      await tester.pumpWidget(buildSurface(tone: tone));

      expect(find.byType(AppGlassSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('blur false skips the backdrop filter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSurface(blur: false));

    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('width and height include the 1px rim', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSurface(width: 120, height: 40));

    final rect = tester.getRect(find.byType(AppGlassSurface));
    expect(rect.width, 120);
    expect(rect.height, 40);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high contrast falls back to an opaque surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSurface(highContrast: true));

    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
