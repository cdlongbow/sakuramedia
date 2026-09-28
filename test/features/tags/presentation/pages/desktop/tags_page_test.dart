import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/tags/presentation/pages/desktop/tags_page.dart';
import 'package:sakuramedia/theme.dart';

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
  });

  tearDown(() {
    bundle.dispose();
  });

  Map<String, dynamic> moviesPage() => <String, dynamic>{
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

  List<String?> movieTagMatches() => bundle.adapter.requests
      .where((request) => request.uri.path == '/movies')
      .map((request) => request.uri.queryParameters['tag_match'])
      .toList(growable: false);

  Future<void> pumpTagsPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
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

  testWidgets('弹窗可连续选择并清空，页面摘要跟随选择', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: [
        {'tag_id': 1, 'name': '标签一', 'movie_count': 10},
        {'tag_id': 2, 'name': '标签二', 'movie_count': 8},
      ],
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/movies',
      body: moviesPage(),
    );
    await pumpTagsPage(tester);
    expect(find.byKey(const Key('tags-option-1')), findsNothing);
    await tester.tap(find.byKey(const Key('tags-selector-trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-selector-dialog')), findsOneWidget);
    // 标签页的 chips 继续显示影片数量。
    expect(find.text('标签一 · 10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tags-option-1')));
    await settleFilterRequest(tester);
    expect(find.byKey(const Key('tags-selector-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tags-option-2')));
    await settleFilterRequest(tester);
    expect(find.byKey(const Key('tags-selected-1')), findsOneWidget);
    expect(find.byKey(const Key('tags-selected-2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tags-clear-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-selector-dialog')), findsOneWidget);
    expect(find.byKey(const Key('tags-selected-1')), findsNothing);
    expect(find.byKey(const Key('tags-selected-2')), findsNothing);
    await tester.tapAt(const Offset(790, 590));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-selector-dialog')), findsNothing);
    expect(find.text('请选择标签查看影片'), findsOneWidget);
    expect(find.byKey(const Key('tags-option-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('弹窗可滚动查看全部标签，末尾标签懒构建', (WidgetTester tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        for (var i = 0; i < 200; i++)
          <String, dynamic>{
            'tag_id': i,
            'name': 'tag$i',
            'movie_count': 300 - i,
          },
      ],
    );

    await pumpTagsPage(tester);
    await tester.tap(find.byKey(const Key('tags-selector-trigger')));
    await tester.pumpAndSettle();

    // 全部标签按影片数降序：首屏是热门标签，末尾标签不在已构建的懒加载块里。
    expect(find.text('全部标签 · 200'), findsOneWidget);
    expect(find.byKey(const Key('tags-option-0')), findsOneWidget);
    expect(find.byKey(const Key('tags-option-199')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('tags-option-199')),
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('tags-cloud-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('tags-option-199')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索在全部标签里过滤结果', (WidgetTester tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        for (var i = 0; i < 200; i++)
          <String, dynamic>{
            'tag_id': i,
            'name': i == 199 ? '冷门标签' : 'tag$i',
            'movie_count': 300 - i,
          },
      ],
    );

    await pumpTagsPage(tester);
    await tester.tap(find.byKey(const Key('tags-selector-trigger')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('tags-search-field')), '冷门');
    await tester.pumpAndSettle();

    expect(find.text('搜索结果 · 1'), findsOneWidget);
    expect(find.byKey(const Key('tags-option-199')), findsOneWidget);
    expect(find.byKey(const Key('tags-option-0')), findsNothing);
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
      ..enqueueJson(method: 'GET', path: '/movies', body: moviesPage())
      ..enqueueJson(method: 'GET', path: '/movies', body: moviesPage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraThemeData,
            home: const Scaffold(body: DesktopTagsPage(initialTagId: 1)),
          ),
        ),
      ),
    );
    await settleFilterRequest(tester);

    // 预选标签首拉影片默认走 or。
    expect(movieTagMatches(), <String?>['or']);

    await tester.tap(find.byKey(const Key('tags-summary-match')));
    await settleFilterRequest(tester);

    // 切到「全部」后追加一次 and 请求。
    expect(movieTagMatches(), <String?>['or', 'and']);
  });
}
