import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/discovery/presentation/widgets/taste_profile_section.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore session;
  late TestApiBundle bundle;
  late List<int> tagTaps;
  late List<int> actorTaps;

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraThemeData,
            locale: const Locale('zh'),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TasteProfileSection(
                  onTagTap: tagTaps.add,
                  onActorTap: actorTaps.add,
                ),
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
    tagTaps = <int>[];
    actorTaps = <int>[];
  });

  tearDown(() {
    bundle.dispose();
    session.dispose();
  });

  testWidgets('renders ranked tags and followable actresses', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileJson(),
    );
    await pumpSection(tester);

    expect(find.byKey(const Key('taste-profile-panel')), findsOneWidget);
    expect(find.text('观影偏好'), findsOneWidget);
    expect(find.text('巨乳'), findsOneWidget);
    expect(find.text('剧情'), findsOneWidget);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(find.text('女优 B'), findsOneWidget);
    expect(find.text('关联 5 部'), findsOneWidget);

    await tester.tap(find.byKey(const Key('taste-tag-7')));
    expect(tagTaps, <int>[7]);

    await tester.tap(find.byKey(const Key('taste-actress-2')));
    expect(actorTaps, <int>[2]);
  });

  testWidgets('narrow layout stacks tags above actresses', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileJson(),
    );
    await pumpSection(tester);

    expect(find.text('常看标签'), findsOneWidget);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('常看标签')).dy,
      lessThan(tester.getTopLeft(find.text('你可能想关注')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides when the sample is too small', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileJson(sampleMovieCount: 1),
    );
    await pumpSection(tester);

    expect(find.byKey(const Key('taste-profile-panel')), findsNothing);
    expect(find.byKey(const Key('taste-profile-error')), findsNothing);
  });

  testWidgets(
    'falls back to subscribed regulars when nobody is left to follow',
    (tester) async {
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/taste-profile',
        body: _profileJson(unsubscribed: false),
      );
      await pumpSection(tester);

      expect(find.text('常看女优'), findsOneWidget);
      expect(find.text('你可能想关注'), findsNothing);
      expect(find.byKey(const Key('taste-follow-2')), findsOneWidget);
    },
  );

  testWidgets('subscribing keeps the card in the recommendation block', (
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
    await pumpSection(tester);

    await tester.tap(find.byKey(const Key('taste-follow-2')));
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('PUT', '/actors/2/subscription'), 1);
    expect(find.text('你可能想关注'), findsOneWidget);
    expect(find.text('常看女优'), findsNothing);
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

  testWidgets('shows an inline retry when the profile fails', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      statusCode: 500,
      body: <String, dynamic>{'message': 'boom'},
    );
    await pumpSection(tester);

    expect(find.byKey(const Key('taste-profile-error')), findsOneWidget);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _profileJson(),
    );
    await tester.tap(find.byKey(const Key('taste-profile-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taste-profile-panel')), findsOneWidget);
  });
}

Map<String, dynamic> _profileJson({
  int sampleMovieCount = 42,
  bool unsubscribed = true,
}) {
  return <String, dynamic>{
    'sample_movie_count': sampleMovieCount,
    'actresses': <dynamic>[
      _actressJson(id: 1, name: '女优 A', isSubscribed: true),
      _actressJson(id: 2, name: '女优 B', isSubscribed: !unsubscribed),
    ],
    'unsubscribed_actresses': unsubscribed
        ? <dynamic>[_actressJson(id: 2, name: '女优 B', isSubscribed: false)]
        : <dynamic>[],
    'tags': <dynamic>[
      <String, dynamic>{'tag_id': 7, 'name': '剧情', 'matched_movie_count': 9},
      <String, dynamic>{'tag_id': 8, 'name': '巨乳', 'matched_movie_count': 12},
    ],
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
    'matched_movie_count': id == 1 ? 12 : 5,
  };
}
