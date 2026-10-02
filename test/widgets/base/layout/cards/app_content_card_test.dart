import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_content_card.dart';

void main() {
  testWidgets('app content card renders the card surface without a title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: AppContentCard(
            key: Key('card'),
            title: null,
            child: Text('内容'),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const Key('card')),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, sakuraThemeData.appColors.surfaceCard);
    expect(decoration.borderRadius, sakuraThemeData.appRadius.lgBorder);
    expect(find.text('内容'), findsOneWidget);
  });

  testWidgets('app content card still renders a title header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: AppContentCard(
            key: Key('card'),
            title: '标题',
            headerTrailing: Text('更多'),
            child: Text('内容'),
          ),
        ),
      ),
    );

    expect(find.text('标题'), findsOneWidget);
    expect(find.text('更多'), findsOneWidget);
    expect(find.text('内容'), findsOneWidget);
  });
}
