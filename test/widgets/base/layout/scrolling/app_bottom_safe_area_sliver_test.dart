import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_bottom_safe_area_sliver.dart';

const double _kViewportHeight = 600;
const double _kContentHeight = 1200;

void main() {
  testWidgets('自建 CustomScrollView 的页面把安全区留白补在末尾', (
    WidgetTester tester,
  ) async {
    await _pumpCustomScrollView(tester, bottomInset: 34);

    expect(
      _scrollPosition(tester).maxScrollExtent,
      moreOrLessEquals(_kContentHeight + 34 - _kViewportHeight),
    );

    // 滚到底留白节点才进入构建范围。
    final position = _scrollPosition(tester);
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    expect(
      tester.getSize(find.byKey(bottomSafeAreaScrollInsetKey)).height,
      moreOrLessEquals(34),
    );
  });

  testWidgets('没有底部安全区时不插入留白节点', (WidgetTester tester) async {
    await _pumpCustomScrollView(tester, bottomInset: 0);

    expect(
      _scrollPosition(tester).maxScrollExtent,
      moreOrLessEquals(_kContentHeight - _kViewportHeight),
    );
    expect(find.byKey(bottomSafeAreaScrollInsetKey), findsNothing);
  });
}

Future<void> _pumpCustomScrollView(
  WidgetTester tester, {
  required double bottomInset,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, _kViewportHeight);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomInset)),
        child: Builder(
          builder: (context) => CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: SizedBox(height: _kContentHeight),
              ),
              ...bottomSafeAreaSliver(context),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ScrollPosition _scrollPosition(WidgetTester tester) {
  return tester.state<ScrollableState>(find.byType(Scrollable)).position;
}
