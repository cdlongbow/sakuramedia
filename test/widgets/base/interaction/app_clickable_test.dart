import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/widgets/base/interaction/app_clickable.dart';

void main() {
  testWidgets('uses click cursor only while enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppClickable(
          enabled: true,
          child: SizedBox(key: Key('clickable-child')),
        ),
      ),
    );

    final child = find.byKey(const Key('clickable-child'));
    expect(
      tester
          .widget<MouseRegion>(
            find.ancestor(of: child, matching: find.byType(MouseRegion)).first,
          )
          .cursor,
      SystemMouseCursors.click,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AppClickable(
          enabled: false,
          child: SizedBox(key: Key('clickable-child')),
        ),
      ),
    );

    expect(
      tester
          .widget<MouseRegion>(
            find.ancestor(of: child, matching: find.byType(MouseRegion)).first,
          )
          .cursor,
      SystemMouseCursors.basic,
    );
  });
}
