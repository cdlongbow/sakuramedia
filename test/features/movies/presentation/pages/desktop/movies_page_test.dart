import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/pages/desktop/movies_page.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/navigation/app_filter_entry_button.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
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

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('筛选浮层内按标签过滤影片，入口摘要与重置纳入标签', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.pumpWidget(wrap(const DesktopMoviesPage()));
    await tester.pumpAndSettle();

    // 标签数据懒加载：面板打开前不发 /tags。
    expect(bundle.adapter.hitCount('GET', '/tags'), 0);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'tag_id': 3, 'name': '巨乳', 'movie_count': 100},
      ],
    );
    await tester.tap(find.byKey(const Key('movies-filter-trigger')));
    await tester.pumpAndSettle();
    expect(bundle.adapter.hitCount('GET', '/tags'), 1);
    expect(find.byKey(const Key('movies-filter-panel')), findsOneWidget);
    // 标签分节在面板最末，先滚到它再操作。
    expect(find.byKey(const Key('tags-option-3')), findsOneWidget);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(total: 1),
    );
    await tester.ensureVisible(find.byKey(const Key('tags-option-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tags-option-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final tagged = bundle.adapter.requests.lastWhere(
      (request) => request.path == '/movies',
    );
    expect(tagged.uri.queryParameters['tag_ids'], '3');
    expect(tagged.uri.queryParameters['tag_match'], 'or');
    // 入口摘要直接反映标签条件。
    final entry = tester.widget<AppFilterEntryButton>(
      find.byType(AppFilterEntryButton),
    );
    expect(entry.label, '标签 · 1');

    // 面板 footer 的重置同时清空标签条件。
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.tap(find.text('重置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final cleared = bundle.adapter.requests.lastWhere(
      (request) => request.path == '/movies',
    );
    expect(cleared.uri.queryParameters.containsKey('tag_ids'), isFalse);
    expect(find.byKey(const Key('tags-selected-3')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _moviesJson({int total = 2}) {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      for (var index = 0; index < total; index++)
        <String, dynamic>{
          'javdb_id': 'MovieA$index',
          'movie_number': 'ABC-00${index + 1}',
          'title': 'Movie $index',
          'cover_image': null,
          'release_date': '2024-01-02',
          'duration_minutes': 120,
          'is_subscribed': false,
          'can_play': true,
        },
    ],
    'page': 1,
    'page_size': 24,
    'total': total,
  };
}
