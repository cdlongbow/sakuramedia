import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/presentation/widgets/actor_taste_recommendation_rail.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore session;
  late TestApiBundle bundle;
  late List<int> actorTaps;

  Future<void> pumpRail(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraThemeData,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ActorTasteRecommendationRail(onActorTap: actorTaps.add),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    session = SessionStore.inMemory();
    await session.saveBaseUrl('https://api.example.com');
    await session.saveTokens(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresAt: DateTime(2099),
    );
    bundle = await createTestApiBundle(session);
    actorTaps = <int>[];
  });

  tearDown(() {
    bundle.dispose();
    session.dispose();
  });

  testWidgets('subscribing keeps the actress in place and fills the heart', (
    tester,
  ) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/actors/2/subscription',
      statusCode: 204,
    );
    await pumpRail(tester);

    expect(find.byKey(const Key('actor-taste-recommendation')), findsOneWidget);
    expect(find.text('常看女优'), findsOneWidget);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(find.text('女优 B'), findsOneWidget);

    await tester.tap(find.byKey(const Key('taste-actress-2')));
    expect(actorTaps, <int>[2]);

    await tester.tap(find.byKey(const Key('taste-follow-2')));
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('PUT', '/actors/2/subscription'), 1);
    expect(find.byKey(const Key('actor-taste-recommendation')), findsOneWidget);
    expect(find.text('已订阅'), findsNothing);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(find.byKey(const Key('taste-actress-2')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('taste-follow-2')),
        matching: find.byIcon(Icons.favorite_rounded),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('subscribing a recommendation-only actress keeps her visible', (
    tester,
  ) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileRecommendedOnly(),
    );
    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/actors/2/subscription',
      statusCode: 204,
    );
    await pumpRail(tester);

    await tester.tap(find.byKey(const Key('taste-follow-2')));
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('PUT', '/actors/2/subscription'), 1);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(find.byKey(const Key('taste-actress-2')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('taste-follow-2')),
        matching: find.byIcon(Icons.favorite_rounded),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('shows subscribed favorites when there is no recommendation', (
    tester,
  ) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileJson(unsubscribed: false),
    );
    await pumpRail(tester);

    expect(find.byKey(const Key('actor-taste-recommendation')), findsOneWidget);
    expect(find.text('常看女优'), findsOneWidget);
    expect(find.text('已订阅'), findsOneWidget);
    expect(find.byKey(const Key('taste-actress-2')), findsOneWidget);
    expect(find.text('你可能想关注'), findsNothing);
  });

  testWidgets('hides when both groups are empty', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _emptyProfileJson(),
    );
    await pumpRail(tester);

    expect(find.byKey(const Key('actor-taste-recommendation')), findsNothing);
  });

  testWidgets('renders subscribed and recommended cards together', (
    tester,
  ) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileWithBoth(),
    );
    await pumpRail(tester);

    expect(find.byKey(const Key('actor-taste-recommendation')), findsOneWidget);
    expect(find.text('已订阅'), findsOneWidget);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(find.byKey(const Key('taste-actress-1')), findsOneWidget);
    expect(find.byKey(const Key('taste-actress-2')), findsOneWidget);
  });

  testWidgets('unsubscribing keeps the card in place and empties the heart', (
    tester,
  ) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileWithBoth(),
    );
    bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/actors/1/subscription',
      statusCode: 204,
    );
    await pumpRail(tester);

    await tester.tap(find.byKey(const Key('taste-follow-1')));
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('DELETE', '/actors/1/subscription'), 1);
    expect(find.text('已订阅'), findsOneWidget);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(find.byKey(const Key('taste-actress-1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('taste-follow-1')),
        matching: find.byIcon(Icons.favorite_border_rounded),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });
}

Map<String, dynamic> _profileJson({bool unsubscribed = true}) {
  return <String, dynamic>{
    'sample_movie_count': 42,
    'actresses': <dynamic>[
      _actressJson(id: 2, name: '女优 B', isSubscribed: !unsubscribed),
    ],
    'unsubscribed_actresses': unsubscribed
        ? <dynamic>[_actressJson(id: 2, name: '女优 B', isSubscribed: false)]
        : <dynamic>[],
    'tags': <dynamic>[],
  };
}

Map<String, dynamic> _profileRecommendedOnly() {
  return <String, dynamic>{
    'sample_movie_count': 42,
    'actresses': <dynamic>[
      _actressJson(id: 1, name: '女优 A', isSubscribed: true),
    ],
    'unsubscribed_actresses': <dynamic>[
      _actressJson(id: 2, name: '女优 B', isSubscribed: false),
    ],
    'tags': <dynamic>[],
  };
}

Map<String, dynamic> _profileWithBoth() {
  return <String, dynamic>{
    'sample_movie_count': 42,
    'actresses': <dynamic>[
      _actressJson(id: 1, name: '女优 A', isSubscribed: true),
      _actressJson(id: 2, name: '女优 B', isSubscribed: false),
    ],
    'unsubscribed_actresses': <dynamic>[
      _actressJson(id: 2, name: '女优 B', isSubscribed: false),
    ],
    'tags': <dynamic>[],
  };
}

Map<String, dynamic> _emptyProfileJson() {
  return <String, dynamic>{
    'sample_movie_count': 42,
    'actresses': <dynamic>[],
    'unsubscribed_actresses': <dynamic>[],
    'tags': <dynamic>[],
  };
}

Map<String, dynamic> _actressJson({
  required int id,
  required String name,
  required bool isSubscribed,
}) {
  return <String, dynamic>{
    'actor': <String, dynamic>{
      'id': id,
      'javdb_id': 'actor-$id',
      'name': name,
      'alias_name': '',
      'display_name': name,
      'is_subscribed': isSubscribed,
    },
    'matched_movie_count': 5,
  };
}
