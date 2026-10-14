import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_no_pull_down_scroll_view.dart';

const double _kViewportHeight = 800;
const Key _kHorizontalStripKey = Key('no-pull-down-horizontal-strip');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS：顶部下拉零位移，底部上滑仍可过卷', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _pumpScrollView(tester, platform: TargetPlatform.iOS);
      final position = _scrollPosition(tester);

      final pullDown = await tester.startGesture(_scrollCenter(tester));
      await pullDown.moveBy(const Offset(0, 300));
      await tester.pump();
      expect(position.pixels, 0);
      expect(position.outOfRange, isFalse);
      await pullDown.up();
      await tester.pumpAndSettle();
      expect(position.pixels, 0);

      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final pushUp = await tester.startGesture(_scrollCenter(tester));
      await pushUp.moveBy(const Offset(0, -300));
      await tester.pump();
      expect(position.pixels, greaterThan(position.maxScrollExtent));
      await pushUp.up();
      await tester.pumpAndSettle();
      expect(
        position.pixels,
        moreOrLessEquals(position.maxScrollExtent, epsilon: 0.5),
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android：顶部下拉压掉拉伸/光晕，底部上滑仍放行', (WidgetTester tester) async {
    final notifications = <OverscrollIndicatorNotification>[];
    await _pumpScrollView(
      tester,
      platform: TargetPlatform.android,
      notifications: notifications,
    );
    final position = _scrollPosition(tester);

    final pullDown = await tester.startGesture(_scrollCenter(tester));
    await pullDown.moveBy(const Offset(0, 300));
    await tester.pump();
    expect(position.pixels, 0);
    await pullDown.up();
    await tester.pumpAndSettle();
    expect(
      notifications.any(
        (notification) =>
            notification.depth == 0 &&
            notification.leading &&
            !notification.accepted,
      ),
      isTrue,
    );

    notifications.clear();
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final pushUp = await tester.startGesture(_scrollCenter(tester));
    await pushUp.moveBy(const Offset(0, -300));
    await tester.pump();
    await pushUp.up();
    await tester.pumpAndSettle();
    expect(
      notifications.any(
        (notification) =>
            notification.depth == 0 &&
            !notification.leading &&
            notification.accepted,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('嵌套横向列表的过卷不被拦截', (WidgetTester tester) async {
    final notifications = <OverscrollIndicatorNotification>[];
    await _pumpScrollView(
      tester,
      platform: TargetPlatform.android,
      notifications: notifications,
      includeHorizontalStrip: true,
    );

    // 横向列表停在起点再往右拖：产生它自己的 leading 过卷。
    await tester.drag(find.byKey(_kHorizontalStripKey), const Offset(300, 0));
    await tester.pumpAndSettle();

    final nested = notifications
        .where((notification) => notification.depth > 0)
        .toList();
    expect(nested, isNotEmpty);
    expect(nested.every((notification) => notification.accepted), isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScrollView(
  WidgetTester tester, {
  required TargetPlatform platform,
  List<OverscrollIndicatorNotification>? notifications,
  bool includeHorizontalStrip = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, _kViewportHeight);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  Widget scrollView = AppNoPullDownScrollView(
    slivers: <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 400, child: Text('A'))),
      if (includeHorizontalStrip)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: ListView(
              key: _kHorizontalStripKey,
              scrollDirection: Axis.horizontal,
              children: List<Widget>.generate(
                4,
                (index) =>
                    const SizedBox(width: 200, child: Text('horizontal')),
              ),
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 1600, child: Text('B'))),
    ],
  );

  if (notifications != null) {
    scrollView = NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        notifications.add(notification);
        return false;
      },
      child: scrollView,
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: sakuraThemeData.copyWith(platform: platform),
      home: Scaffold(body: scrollView),
    ),
  );
  await tester.pumpAndSettle();
}

ScrollPosition _scrollPosition(WidgetTester tester) {
  return tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(AppNoPullDownScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;
}

Offset _scrollCenter(WidgetTester tester) {
  return tester.getCenter(find.byType(AppNoPullDownScrollView));
}
