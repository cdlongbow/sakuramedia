import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/tags/presentation/pages/mobile/tags_page.dart';
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

  List<String?> movieTagMatches() => movieRequests()
      .map((request) => request.uri.queryParameters['tag_match'])
      .toList(growable: false);

  ResponseBody moviesResponse(String movieNumber) => ResponseBody.fromString(
    jsonEncode(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'javdb_id': 'MovieA-$movieNumber',
          'movie_number': movieNumber,
          'title': 'Movie $movieNumber',
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
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  Widget wrap(Widget child) {
    return ProviderScope(
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
          home: Scaffold(body: child),
        ),
      ),
    );
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
    await tester.pumpWidget(wrap(const MobileTagsPage()));
    await tester.pumpAndSettle();

    expect(find.text('按标签发现'), findsOneWidget);
    expect(find.byKey(const Key('tags-cloud-tag-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-confirm')), findsNothing);
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('tags-cloud-tag-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-browse-selected-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-confirm')), findsOneWidget);
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('tags-cloud-tag-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-browse-selected-2')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-match-or')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tags-browse-clear')));
    await tester.pumpAndSettle();
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
      ],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _tasteProfileJson(tagId: 1, name: '标签一'),
    );
    await tester.pumpWidget(wrap(const MobileTagsPage()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(wrap(const MobileTagsPage()));
    await tester.pumpAndSettle();

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

  testWidgets('窄屏大字体下浏览态可滚动，CTA 不溢出', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: [
        for (var index = 1; index <= 5; index++)
          {
            'tag_id': index,
            'name': index == 1 ? '这是比较长的标签名称' : '标签$index',
            'movie_count': 10,
          },
      ],
    );
    await tester.pumpWidget(wrap(const MobileTagsPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tags-browse-search')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('tags-cloud-tag-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tags-cloud-tag-5')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tags-browse-confirm')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-selected-5')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('结果页修改后取消恢复原选择', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: [
        {'tag_id': 1, 'name': '标签一', 'movie_count': 10},
        {'tag_id': 2, 'name': '标签二', 'movie_count': 8},
      ],
    );
    await tester.pumpWidget(wrap(const MobileTagsPage(initialTagId: 1)));
    await settleFilterRequest(tester);

    expect(find.byKey(const Key('tags-summary-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tags-edit-selection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-browse-selected-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-browse-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tags-cloud-tag-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-browse-selected-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tags-browse-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-summary-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-summary-2')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('一级入口确认后防抖再请求，加载中不显示空态', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'tag_id': 1, 'name': '巨乳', 'movie_count': 100},
      ],
    );
    final held = Completer<ResponseBody>();
    bundle.adapter.enqueueResponder(
      method: 'GET',
      path: '/movies',
      responder: (_, _) => held.future,
    );
    addTearDown(() {
      if (!held.isCompleted) held.complete(moviesResponse('REAL-777'));
    });

    await tester.pumpWidget(wrap(const MobileTagsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tags-cloud-tag-1')));
    await tester.pumpAndSettle();
    expect(movieRequests(), isEmpty);

    await tester.tap(find.byKey(const Key('tags-browse-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(bundle.adapter.hitCount('GET', '/movies'), 0);
    expect(find.text('该标签下暂无影片'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    expect(bundle.adapter.hitCount('GET', '/movies'), 1);
    expect(find.text('该标签下暂无影片'), findsNothing);

    held.complete(moviesResponse('REAL-777'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-summary-card-REAL-777')),
      findsOneWidget,
    );
    expect(find.text('该标签下暂无影片'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preselected tag fetches movies with tag_match=or then and on toggle',
    (WidgetTester tester) async {
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

      await tester.pumpWidget(wrap(const MobileTagsPage(initialTagId: 1)));
      await settleFilterRequest(tester);

      expect(movieTagMatches(), <String?>['or']);

      await tester.tap(find.byKey(const Key('tags-summary-match')));
      await settleFilterRequest(tester);

      expect(movieTagMatches(), <String?>['or', 'and']);
    },
  );

  testWidgets('详情跳入的预选标签首拉不等防抖，加载中显示骨架而不是空态', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'tag_id': 1, 'name': '巨乳', 'movie_count': 100},
      ],
    );
    final held = Completer<ResponseBody>();
    bundle.adapter.enqueueResponder(
      method: 'GET',
      path: '/movies',
      responder: (_, _) => held.future,
    );
    addTearDown(() {
      if (!held.isCompleted) held.complete(moviesResponse('REAL-777'));
    });

    await tester.pumpWidget(wrap(const MobileTagsPage(initialTagId: 1)));
    await tester.pump();
    // 250ms 防抖窗口内就已经发出首拉。
    await tester.pump(const Duration(milliseconds: 100));
    expect(bundle.adapter.hitCount('GET', '/movies'), 1);

    expect(find.text('该标签下暂无影片'), findsNothing);
    expect(find.byKey(const Key('movie-summary-card-ABC-001')), findsOneWidget);
    expect(find.byKey(const Key('movie-summary-card-REAL-777')), findsNothing);

    held.complete(moviesResponse('REAL-777'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-summary-card-REAL-777')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('movie-summary-card-ABC-001')), findsNothing);
    expect(find.text('该标签下暂无影片'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('影片筛选走底部抽屉，而不是桌面就地浮层', (tester) async {
    bundle.adapter
      ..enqueueJson(
        method: 'GET',
        path: '/tags',
        body: <Map<String, dynamic>>[
          <String, dynamic>{'tag_id': 1, 'name': '巨乳', 'movie_count': 100},
        ],
      )
      ..enqueueJson(method: 'GET', path: '/movies', body: _moviesPage());

    await tester.pumpWidget(wrap(const MobileTagsPage(initialTagId: 1)));
    await settleFilterRequest(tester);

    await tester.tap(find.byKey(const Key('mobile-tags-filter-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile-movies-filter-drawer')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('movies-filter-panel')), findsNothing);
  });

  testWidgets('多选走移动布局：顶栏只留计数/全选，批量动作在底部条且不溢出', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(374, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter
      ..enqueueJson(
        method: 'GET',
        path: '/tags',
        body: <Map<String, dynamic>>[
          <String, dynamic>{'tag_id': 1, 'name': '巨乳', 'movie_count': 100},
        ],
      )
      ..enqueueJson(method: 'GET', path: '/movies', body: _moviesPage());

    await tester.pumpWidget(wrap(const MobileTagsPage(initialTagId: 1)));
    await settleFilterRequest(tester);

    expect(
      find.byKey(const Key('movie-list-enter-selection-button')),
      findsNothing,
    );

    await tester.longPress(find.byKey(const Key('movie-summary-card-ABC-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('app-list-header-selection-label')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-list-batch-bottom-bar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
