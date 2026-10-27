import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/tags/presentation/pages/desktop/tags_page.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/fake_http_client_adapter.dart';
import '../../../../../support/test_api_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/taste-profile',
      body: _emptyTasteProfileJson(),
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/movies',
      body: _moviesPage(),
    );
  });

  tearDown(() {
    bundle.dispose();
  });

  List<RecordedRequest> movieRequests() => bundle.adapter.requests
      .where((request) => request.uri.path == '/movies')
      .toList(growable: false);

  Future<void> pumpTagsPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
            theme: sakuraThemeData,
            home: const Scaffold(body: DesktopTagsPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleFilterRequest(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pumpAndSettle();
  }

  testWidgets('浏览态连续选择、清空，确认后才请求影片', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: [
        {'tag_id': 1, 'name': '标签一', 'movie_count': 10},
        {'tag_id': 2, 'name': '标签二', 'movie_count': 8},
      ],
    );
    await pumpTagsPage(tester);

    expect(find.text('按标签发现'), findsOneWidget);
    expect(find.byKey(const Key('tags-cloud-tag-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-confirm')), findsNothing);
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('tags-cloud-tag-1')));
    await tester.pump();
    expect(find.byKey(const Key('tags-browse-selected-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-confirm')), findsOneWidget);
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('tags-cloud-tag-2')));
    await tester.pump();
    expect(find.byKey(const Key('tags-browse-selected-2')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-match-or')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tags-browse-clear')));
    await tester.pump();
    expect(find.byKey(const Key('tags-browse-selected-1')), findsNothing);
    expect(find.byKey(const Key('tags-browse-confirm')), findsNothing);
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('tags-cloud-tag-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tags-browse-confirm')));
    await settleFilterRequest(tester);

    expect(find.byKey(const Key('tags-edit-selection')), findsOneWidget);
    expect(find.byKey(const Key('tags-summary-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-page-movies')), findsOneWidget);
    expect(movieRequests(), hasLength(1));
    expect(movieRequests().single.uri.queryParameters['tag_ids'], '1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('常看标签进入为你区，选中后确认进入结果', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: [
        {'tag_id': 1, 'name': '标签一', 'movie_count': 10},
        {'tag_id': 2, 'name': '标签二', 'movie_count': 8},
        {'tag_id': 3, 'name': '标签三', 'movie_count': 6},
      ],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _tasteProfileJson(tagId: 1, name: '标签一'),
    );
    await pumpTagsPage(tester);

    expect(find.text('为你'), findsOneWidget);
    expect(find.byKey(const Key('taste-cloud-tag-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-cloud-tag-1')), findsNothing);
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('taste-cloud-tag-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-browse-selected-1')), findsOneWidget);
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('tags-browse-confirm')));
    await settleFilterRequest(tester);

    expect(find.byKey(const Key('tags-summary-1')), findsOneWidget);
    expect(movieRequests(), hasLength(1));
    expect(movieRequests().single.uri.queryParameters['tag_ids'], '1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索可找到长尾标签并直接确认', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        for (var index = 0; index < 200; index++)
          <String, dynamic>{
            'tag_id': index,
            'name': index == 199 ? '冷门标签' : 'tag$index',
            'movie_count': 300 - index,
          },
      ],
    );
    await pumpTagsPage(tester);

    expect(find.byKey(const Key('tags-cloud-tag-199')), findsNothing);
    await tester.enterText(find.byKey(const Key('tags-browse-search')), '冷门');
    await tester.pumpAndSettle();

    expect(find.text('搜索结果'), findsOneWidget);
    expect(find.byKey(const Key('tags-search-option-199')), findsOneWidget);
    expect(find.byKey(const Key('tags-cloud-tag-0')), findsNothing);

    await tester.tap(find.byKey(const Key('tags-search-option-199')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tags-browse-confirm')));
    await settleFilterRequest(tester);

    expect(find.byKey(const Key('tags-summary-199')), findsOneWidget);
    expect(movieRequests(), hasLength(1));
    expect(movieRequests().single.uri.queryParameters['tag_ids'], '199');
    expect(tester.takeException(), isNull);
  });

  testWidgets('结果页修改后取消恢复原选择，清空回到浏览态', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: [
        {'tag_id': 1, 'name': '标签一', 'movie_count': 10},
        {'tag_id': 2, 'name': '标签二', 'movie_count': 8},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
            theme: sakuraThemeData,
            home: const Scaffold(body: DesktopTagsPage(initialTagId: 1)),
          ),
        ),
      ),
    );
    await settleFilterRequest(tester);

    expect(find.byKey(const Key('tags-summary-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tags-edit-selection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-browse-selected-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tags-cloud-tag-2')));
    await tester.pump();
    expect(find.byKey(const Key('tags-browse-selected-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tags-browse-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-summary-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-summary-2')), findsNothing);

    await tester.tap(find.byKey(const Key('tags-summary-clear')));
    await tester.pumpAndSettle();
    expect(find.text('按标签发现'), findsOneWidget);
    expect(find.byKey(const Key('tags-edit-selection')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching tag match mode reloads movies with tag_match=and', (
    WidgetTester tester,
  ) async {
    bundle.adapter
      ..enqueueJson(
        method: 'GET',
        path: '/tags',
        body: <Map<String, dynamic>>[
          <String, dynamic>{'tag_id': 1, 'name': '巨乳', 'movie_count': 100},
          <String, dynamic>{'tag_id': 2, 'name': '单体作品', 'movie_count': 80},
        ],
      )
      ..enqueueJson(method: 'GET', path: '/movies', body: _moviesPage())
      ..enqueueJson(method: 'GET', path: '/movies', body: _moviesPage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
            theme: sakuraThemeData,
            home: const Scaffold(body: DesktopTagsPage(initialTagId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();
    // 预选标签首拉不等 250ms 防抖窗口。
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      movieRequests().map(
        (request) => request.uri.queryParameters['tag_match'],
      ),
      <String?>['or'],
    );
    await settleFilterRequest(tester);

    await tester.tap(find.byKey(const Key('tags-summary-match')));
    await settleFilterRequest(tester);

    expect(
      movieRequests().map(
        (request) => request.uri.queryParameters['tag_match'],
      ),
      <String?>['or', 'and'],
    );
  });
}

Map<String, dynamic> _moviesPage() {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'javdb_id': 'MovieA1',
        'movie_number': 'ABC-001',
        'title': 'Movie 1',
        'cover_image': null,
        'release_date': '2024-01-02',
        'duration_minutes': 120,
        'is_subscribed': false,
        'can_play': true,
      },
    ],
    'page': 1,
    'page_size': 24,
    'total': 1,
  };
}

Map<String, dynamic> _emptyTasteProfileJson() {
  return const <String, dynamic>{
    'sample_movie_count': 0,
    'actresses': <dynamic>[],
    'unsubscribed_actresses': <dynamic>[],
    'tags': <dynamic>[],
  };
}

Map<String, dynamic> _tasteProfileJson({
  required int tagId,
  required String name,
}) {
  return <String, dynamic>{
    'sample_movie_count': 42,
    'actresses': <dynamic>[],
    'unsubscribed_actresses': <dynamic>[],
    'tags': <dynamic>[
      <String, dynamic>{
        'tag_id': tagId,
        'name': name,
        'matched_movie_count': 12,
      },
    ],
  };
}
