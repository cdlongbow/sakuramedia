import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/domain/collections/collection_member_views.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required VoidCallback onTap,
    VoidCallback? onPlay,
    bool selectionMode = false,
    double width = 480,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: CollectionMemberCard(
                key: const Key('member-card-1'),
                coverUrl: null,
                coverAspectRatio: 16 / 9,
                title: 'ABC-001',
                subtitle: 'JAV · 01:30',
                onPlay: onPlay,
                playButtonKey: const Key('member-card-play-1'),
                onTap: onTap,
                menuKey: const Key('member-card-menu-1'),
                selectionMode: selectionMode,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> hoverCard(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('member-card-1'))));
    await tester.pumpAndSettle();
  }

  testWidgets('member card keeps the cover clean until hovered', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, onTap: () {}, onPlay: () {});

    expect(find.text('ABC-001'), findsNothing);
    expect(find.textContaining('01:30', findRichText: true), findsNothing);
    expect(find.byKey(const Key('member-card-play-1')), findsNothing);

    await hoverCard(tester);

    expect(
      find.textContaining('ABC-001', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('JAV · 01:30', findRichText: true),
      findsOneWidget,
    );
    expect(find.byKey(const Key('member-card-play-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hover play button plays without opening the card', (
    WidgetTester tester,
  ) async {
    var tapped = 0;
    var played = 0;
    await pumpCard(tester, onTap: () => tapped++, onPlay: () => played++);

    await hoverCard(tester);
    await tester.tap(find.byKey(const Key('member-card-play-1')));
    await tester.pump();

    expect(played, 1);
    expect(tapped, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection mode never expands the hover panel', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, onTap: () {}, onPlay: () {}, selectionMode: true);

    await hoverCard(tester);

    expect(find.text('ABC-001'), findsNothing);
    expect(find.byKey(const Key('member-card-play-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton state collapses the member card into one block', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 480,
              child: AppSkeletonizer(
                enabled: true,
                child: CollectionMemberCard(
                  key: const Key('member-card-skeleton'),
                  coverUrl: null,
                  coverAspectRatio: 16 / 9,
                  title: 'ABC-001',
                  onTap: () {},
                  menuKey: const Key('member-card-skeleton-menu'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // 缺图占位不再自带居中图标（会被 skeletonizer 画成实心方块），
    // 整卡由 AppSkeletonUnite 收敛成一块 shimmer 圆角块。
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(AppSkeletonUnite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
