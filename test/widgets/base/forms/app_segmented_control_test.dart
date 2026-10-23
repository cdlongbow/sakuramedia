import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/forms/app_segmented_control.dart';
import 'package:sakuramedia/widgets/base/layout/glass/app_glass_surface.dart';

void main() {
  testWidgets('renders items and forwards selection', (
    WidgetTester tester,
  ) async {
    final changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: AppSegmentedControl<String>(
            items: const <AppSegmentedItem<String>>[
              AppSegmentedItem<String>(
                key: Key('segment-a'),
                value: 'a',
                label: 'A',
              ),
              AppSegmentedItem<String>(
                key: Key('segment-b'),
                value: 'b',
                label: 'B',
              ),
            ],
            selected: 'a',
            onChanged: changes.add,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('segment-a')), findsOneWidget);
    expect(find.byKey(const Key('segment-b')), findsOneWidget);
    final track = tester.widget<AppGlassSurface>(
      find.byType(AppGlassSurface).first,
    );
    expect(track.tone, AppGlassTone.track);

    await tester.tap(find.byKey(const Key('segment-b')));
    await tester.pump();

    expect(changes, <String>['b']);
  });

  testWidgets('selected pill uses the raised surface in dark mode', (
    WidgetTester tester,
  ) async {
    final darkTheme = buildSakuraDesktopThemeData(brightness: Brightness.dark);

    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
        home: const Scaffold(
          body: AppSegmentedControl<String>(
            items: <AppSegmentedItem<String>>[
              AppSegmentedItem<String>(
                key: Key('segment-a'),
                value: 'a',
                label: 'A',
              ),
              AppSegmentedItem<String>(
                key: Key('segment-b'),
                value: 'b',
                label: 'B',
              ),
            ],
            selected: 'a',
            onChanged: _noop,
          ),
        ),
      ),
    );

    final selected = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('segment-a')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = selected.decoration! as BoxDecoration;

    expect(decoration.color, darkTheme.appColors.surfaceElevated);
    expect(decoration.border, isNotNull);
  });
}

void _noop(String value) {}
