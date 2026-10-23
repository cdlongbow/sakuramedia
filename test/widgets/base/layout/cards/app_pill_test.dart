import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_pill.dart';

void main() {
  testWidgets('app pill uses tone colors and renders leading/trailing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: AppPill(
            label: '错误',
            tone: AppPillTone.error,
            leading: Icon(Icons.error_outline),
            trailing: Icon(Icons.close),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;
    final text = tester.widget<Text>(find.text('错误'));

    expect(decoration.color, sakuraThemeData.appColors.errorSurface);
    expect(decoration.borderRadius, AppRadius.defaults().pillBorder);
    expect(text.style?.color, sakuraThemeData.appTextPalette.error);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('compact size is shorter than regular', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: Row(
            children: <Widget>[
              AppPill(key: Key('regular'), label: '常规'),
              AppPill(
                key: Key('compact'),
                label: '紧凑',
                size: AppPillSize.compact,
              ),
            ],
          ),
        ),
      ),
    );

    final regular = tester.getSize(find.byKey(const Key('regular')));
    final compact = tester.getSize(find.byKey(const Key('compact')));

    expect(compact.height, lessThan(regular.height));
  });

  testWidgets('app pill button forwards taps', (WidgetTester tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: AppPillButton(
            key: const Key('pill-button'),
            label: '筛选',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pill-button')));
    await tester.pump();

    expect(taps, 1);
  });
}
