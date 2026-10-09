import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_hover_scroll_rail.dart';

const Key _railKey = Key('test-rail');
const Key _leftArrow = Key('hover-rail-arrow-left');
const Key _rightArrow = Key('hover-rail-arrow-right');

void main() {
  Future<void> pumpRail(WidgetTester tester, {required int itemCount}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: AppHoverScrollRail(
                scrollViewKey: _railKey,
                height: 100,
                itemCount: itemCount,
                itemBuilder: (context, index) => SizedBox(
                  width: 80,
                  child: ColoredBox(
                    key: ValueKey<String>('rail-item-$index'),
                    color: const Color(0xFFCCCCCC),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> hoverRail(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(_railKey)));
    await tester.pump();
  }

  double railOffset(WidgetTester tester) {
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(_railKey),
        matching: find.byType(Scrollable),
      ),
    );
    return scrollable.position.pixels;
  }

  testWidgets('未 hover 时不显示翻页箭头', (tester) async {
    await pumpRail(tester, itemCount: 20);

    expect(find.byKey(_leftArrow), findsNothing);
    expect(find.byKey(_rightArrow), findsNothing);
  });

  testWidgets('hover 显示右侧箭头，点击向右翻页并出现左侧箭头', (tester) async {
    await pumpRail(tester, itemCount: 20);
    await hoverRail(tester);

    expect(find.byKey(_rightArrow), findsOneWidget);
    expect(find.byKey(_leftArrow), findsNothing);

    final before = railOffset(tester);
    await tester.tap(find.byKey(_rightArrow));
    await tester.pumpAndSettle();
    final after = railOffset(tester);

    expect(after, greaterThan(before));
    expect(find.byKey(_leftArrow), findsOneWidget);
  });

  testWidgets('滚到末尾后右侧箭头消失', (tester) async {
    await pumpRail(tester, itemCount: 20);
    await hoverRail(tester);

    await tester.drag(find.byKey(_railKey), const Offset(-4000, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(_rightArrow), findsNothing);
    expect(find.byKey(_leftArrow), findsOneWidget);
  });

  testWidgets('内容不足一屏时即使 hover 也不显示箭头', (tester) async {
    await pumpRail(tester, itemCount: 3);
    await hoverRail(tester);

    expect(find.byKey(_leftArrow), findsNothing);
    expect(find.byKey(_rightArrow), findsNothing);
  });
}
