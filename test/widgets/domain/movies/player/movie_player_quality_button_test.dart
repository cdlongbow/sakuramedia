import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_switch.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_quality_button.dart';

Color _trackColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(AppSwitch),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  group('MoviePlayerQualityButton', () {
    testWidgets('switch follows the enabled listenable', (tester) async {
      final enabled = ValueNotifier<bool>(false);
      addTearDown(enabled.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: MoviePlayerQualityButton(
              label: '画质增强',
              enabledListenable: enabled,
              onPressed: () {},
            ),
          ),
        ),
      );

      final offColor = _trackColor(tester);
      expect(offColor, isNot(sakuraThemeData.colorScheme.primaryContainer));

      enabled.value = true;
      await tester.pumpAndSettle();

      expect(_trackColor(tester), sakuraThemeData.colorScheme.primaryContainer);
    });

    testWidgets('label and switch each report exactly one tap', (
      tester,
    ) async {
      final enabled = ValueNotifier<bool>(false);
      addTearDown(enabled.dispose);
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: MoviePlayerQualityButton(
              label: '画质增强',
              enabledListenable: enabled,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('movie-player-quality-button-label')),
      );
      expect(taps, 1);

      await tester.tap(find.byKey(const Key('movie-player-quality-button')));
      expect(taps, 2);
    });

    testWidgets('switch-only form renders without a label', (tester) async {
      final enabled = ValueNotifier<bool>(false);
      addTearDown(enabled.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: MoviePlayerQualityButton(
              enabledListenable: enabled,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('movie-player-quality-button-label')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('movie-player-quality-button')),
        findsOneWidget,
      );
    });
  });
}
