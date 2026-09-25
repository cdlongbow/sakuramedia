import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'actor summary card falls back to name and shows placeholder without image',
    (WidgetTester tester) async {
      final sessionStore = SessionStore.inMemory();
      await sessionStore.saveBaseUrl('https://api.example.com');

      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: ActorSummaryCard(
              actor: const ActorListItemDto(
                id: 2,
                javdbId: 'Actor2',
                name: '桥本有菜',
                aliasName: '',
                profileImage: null,
                isSubscribed: false,
              ),
              onSubscriptionTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('桥本有菜'), findsOneWidget);
      expect(
        find.byKey(const Key('actor-summary-card-placeholder-2')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    },
  );

  testWidgets('actor summary card shows subscribed badge and alias name', (
    WidgetTester tester,
  ) async {
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: ActorSummaryCard(
            actor: const ActorListItemDto(
              id: 1,
              javdbId: 'Actor1',
              name: '三上悠亚',
              aliasName: '三上悠亚 / 鬼头桃菜',
              profileImage: null,
              isSubscribed: true,
            ),
            onSubscriptionTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('三上悠亚 / 鬼头桃菜'), findsOneWidget);
    expect(
      find.byKey(const Key('actor-summary-card-subscription-1')),
      findsOneWidget,
    );

    final cardRect = tester.getRect(
      find.byKey(const Key('actor-summary-card-1')),
    );
    final subscriptionRect = tester.getRect(
      find.byKey(const Key('actor-summary-card-subscription-1')),
    );
    final edgeInset = AppSpacing.defaults().xs;

    expect(subscriptionRect.top - cardRect.top, closeTo(edgeInset, 0.1));
    expect(subscriptionRect.left - cardRect.left, closeTo(edgeInset, 0.1));

    final bookmarkIcon = tester.widget<Icon>(
      find.byIcon(Icons.favorite_rounded),
    );
    expect(bookmarkIcon.color, AppColors.defaults().subscriptionHeartIcon);
    expect(bookmarkIcon.size, AppComponentTokens.defaults().iconSizeXl);
  });

  testWidgets(
    'actor summary card shows loading indicator while subscription updates',
    (WidgetTester tester) async {
      final sessionStore = SessionStore.inMemory();
      await sessionStore.saveBaseUrl('https://api.example.com');

      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: ActorSummaryCard(
              actor: const ActorListItemDto(
                id: 3,
                javdbId: 'Actor3',
                name: '新有菜',
                aliasName: '',
                profileImage: null,
                isSubscribed: true,
              ),
              onSubscriptionTap: () {},
              isSubscriptionUpdating: true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('actor-summary-card-subscription-loading-3')),
        findsOneWidget,
      );
    },
  );

  testWidgets('actor summary card reveals subscription action on hover', (
    WidgetTester tester,
  ) async {
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    var subscribed = 0;
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: ActorSummaryCard(
            actor: const ActorListItemDto(
              id: 4,
              javdbId: 'Actor4',
              name: '深田咏美',
              aliasName: '',
              profileImage: null,
              isSubscribed: false,
            ),
            onTap: () => tapped++,
            onSubscriptionTap: () => subscribed++,
          ),
        ),
      ),
    );

    // 收起态：姓名常显，悬停动作不在树里。
    expect(find.text('深田咏美'), findsOneWidget);
    expect(
      find.byKey(const Key('actor-summary-card-subscription-action-4')),
      findsNothing,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('actor-summary-card-4'))),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('actor-summary-card-subscription-action-4')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('actor-summary-card-subscription-action-4')),
    );
    await tester.pump();
    expect(subscribed, 1);
    expect(tapped, 0);
    expect(tester.takeException(), isNull);
  });
}
