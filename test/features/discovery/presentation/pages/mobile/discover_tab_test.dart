import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/discovery/presentation/mobile_overview_discover_tab.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/subscription_heart_badge.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets(
    'mobile discover tab shows followed actress releases and recommendations',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueDiscoveryResponses(bundle);
      _enqueueFollowPage(bundle);
      _enqueueSubscription(bundle, movieNumber: 'HOT-001');

      await _pumpDiscoveryWidget(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const MobileOverviewDiscoverTab(),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('mobile-overview-discover-tab')),
        findsWidgets,
      );
      expect(find.text('今日发现'), findsNothing);
      expect(
        find.byKey(const Key('mobile-discover-summary-card')),
        findsNothing,
      );
      expect(find.byKey(const Key('movie-summary-grid')), findsNWidgets(3));
      expect(find.text('女优上新'), findsOneWidget);
      expect(
        find.byKey(const Key('movie-summary-card-FOLLOW-001')),
        findsOneWidget,
      );
      expect(find.text('热门新片'), findsOneWidget);
      expect(
        find.byKey(const Key('movie-summary-card-HOT-001')),
        findsOneWidget,
      );
      expect(find.text('热门：女优 A'), findsOneWidget);
      expect(
        find.byKey(const Key('movie-summary-card-ABC-001')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('moment-grid')), findsOneWidget);
      expect(find.byKey(const Key('moment-card-1')), findsOneWidget);
      expect(
        find.byKey(const Key('mobile-discover-load-more-hot-actress')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mobile-discover-load-more-follow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mobile-discover-load-more-daily')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mobile-discover-load-more-moments')),
        findsOneWidget,
      );
      expect(find.text('近期热度较高'), findsNothing);
      expect(find.text('与你收藏的时刻画面相似'), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('movie-summary-card-subscription-HOT-001')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('movie-summary-card-subscription-HOT-001')),
      );
      await tester.pumpAndSettle();

      expect(bundle.adapter.hitCount('PUT', '/movies/HOT-001/subscription'), 1);
      expect(
        tester
            .widget<SubscriptionHeartBadge>(
              find.byKey(const Key('movie-summary-card-subscription-HOT-001')),
            )
            .isSubscribed,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('长按「发现」Tab 影片卡弹出影片合集菜单', (tester) async {
    final sessionStore = await _buildSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueDiscoveryResponses(bundle);
    _enqueueFollowPage(bundle);
    _enqueueCollectionStatus(bundle, movieNumber: 'ABC-001');
    _enqueueCollectionStatus(bundle, movieNumber: 'HOT-001');
    _enqueueCollectionStatus(bundle, movieNumber: 'FOLLOW-001');

    await _pumpDiscoveryWidget(
      tester,
      sessionStore: sessionStore,
      bundle: bundle,
      child: const MobileOverviewDiscoverTab(),
    );
    await tester.pumpAndSettle();

    // 今日推荐（未订阅）：订阅影片 / 标记为合集 / 屏蔽影片。
    await _longPressMovieCard(tester, 'movie-summary-card-ABC-001');
    expect(find.text('订阅影片'), findsOneWidget);
    expect(find.text('标记为合集'), findsOneWidget);
    expect(find.text('屏蔽影片'), findsOneWidget);
    await _dismissMenu(tester);

    // 热门新片（未订阅）同样接入长按菜单。
    await _longPressMovieCard(tester, 'movie-summary-card-HOT-001');
    expect(find.text('订阅影片'), findsOneWidget);
    await _dismissMenu(tester);

    // 女优上新（已订阅）：显示取消订阅，且不出现屏蔽项。
    await _longPressMovieCard(tester, 'movie-summary-card-FOLLOW-001');
    expect(find.text('取消订阅'), findsOneWidget);
    expect(find.text('屏蔽影片'), findsNothing);
    await _dismissMenu(tester);

    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('移动推荐时刻预览统一为底部抽屉，封面可进影片详情', (tester) async {
    final sessionStore = await _buildSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueDiscoveryResponses(bundle);
    _enqueueFollowPage(bundle);
    _enqueueMomentPreviewMovie(bundle);
    _enqueueEmptyMediaPoints(bundle, mediaId: 101);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(body: MobileOverviewDiscoverTab()),
        ),
        GoRoute(
          path: '$mobileMoviesPath/:movieNumber',
          builder: (_, __) => const Scaffold(body: Text('movie-detail')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpDiscoveryRouterApp(
      tester,
      sessionStore: sessionStore,
      bundle: bundle,
      router: router,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('moment-card-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moment-card-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile-discover-moment-preview-bottom-sheet')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('image-search-result-preview-movie-cover')),
    );
    await tester.pumpAndSettle();

    expect(find.text('movie-detail'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _longPressMovieCard(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

Future<void> _dismissMenu(WidgetTester tester) async {
  await tester.tapAt(const Offset(4, 4));
  await tester.pumpAndSettle();
}

Future<SessionStore> _buildSessionStore() async {
  final sessionStore = SessionStore.inMemory();
  await sessionStore.saveBaseUrl('https://api.example.com');
  await sessionStore.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.parse('2026-05-08T12:00:00Z'),
  );
  return sessionStore;
}

Future<void> _pumpDiscoveryWidget(
  WidgetTester tester, {
  required SessionStore sessionStore,
  required TestApiBundle bundle,
  required Widget child,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => child,
          ),
          home: child,
        ),
      ),
    ),
  );
}

Future<void> _pumpDiscoveryRouterApp(
  WidgetTester tester, {
  required SessionStore sessionStore,
  required TestApiBundle bundle,
  required GoRouter router,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: AppPlatformScope(
        platform: AppPlatform.mobile,
        child: OKToast(
          child: MaterialApp.router(
            theme: sakuraMobileThemeData,
            routerConfig: router,
          ),
        ),
      ),
    ),
  );
}

void _enqueueEmptyMediaPoints(TestApiBundle bundle, {required int mediaId}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/media/$mediaId/points',
    body: const <dynamic>[],
  );
}

void _enqueueMomentPreviewMovie(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/ABC-001',
    body: <String, dynamic>{
      'javdb_id': 'MovieA1',
      'movie_number': 'ABC-001',
      'title': 'Movie 1',
      'series_name': '',
      'cover_image': <String, dynamic>{
        'id': 1,
        'origin': '/cover.jpg',
      },
      'release_date': null,
      'duration_minutes': 0,
      'score': 0,
      'watched_count': 0,
      'want_watch_count': 0,
      'comment_count': 0,
      'score_number': 0,
      'is_collection': false,
      'is_subscribed': false,
      'can_play': true,
      'summary': '',
      'thin_cover_image': null,
      'plot_images': const <Map<String, dynamic>>[],
      'actors': const <Map<String, dynamic>>[],
      'tags': const <Map<String, dynamic>>[],
      'media_items': const <Map<String, dynamic>>[],
    },
  );
}

void _enqueueDiscoveryResponses(TestApiBundle bundle) {
  _enqueueHotActressPage(bundle, page: 1, start: 1, count: 1, total: 1);
  _enqueueDailyPage(bundle, page: 1, start: 1, count: 1, total: 1);
  _enqueueMomentPage(bundle, page: 1, start: 1, count: 1, total: 1);
}

void _enqueueSubscription(TestApiBundle bundle, {required String movieNumber}) {
  bundle.adapter.enqueueJson(
    method: 'PUT',
    path: '/movies/$movieNumber/subscription',
    statusCode: 204,
  );
}

void _enqueueCollectionStatus(
  TestApiBundle bundle, {
  required String movieNumber,
  bool isCollection = false,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/$movieNumber/collection-status',
    body: <String, dynamic>{
      'movie_number': movieNumber,
      'is_collection': isCollection,
    },
  );
}

void _enqueueFollowPage(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/subscribed-actors/latest',
    body: <String, dynamic>{
      'items': <Map<String, dynamic>>[_followMovieJson()],
      'page': 1,
      'page_size': 10,
      'total': 1,
    },
  );
}

Map<String, dynamic> _followMovieJson() => <String, dynamic>{
  'javdb_id': 'follow-id-001',
  'movie_number': 'FOLLOW-001',
  'title': 'Follow movie 001',
  'cover_image': null,
  'thin_cover_image': null,
  'release_date': '2026-05-01',
  'duration_minutes': 120,
  'heat': 0,
  'is_subscribed': true,
  'can_play': false,
};

void _enqueueHotActressPage(
  TestApiBundle bundle, {
  required int page,
  required int start,
  required int count,
  required int total,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/hot-actress-releases',
    body: <String, dynamic>{
      'items': List<Map<String, dynamic>>.generate(
        count,
        (index) => _hotActressMovieJson(start + index),
      ),
      'page': page,
      'page_size': count,
      'total': total,
    },
  );
}

Map<String, dynamic> _hotActressMovieJson(int index) {
  final number = index.toString().padLeft(3, '0');
  return <String, dynamic>{
    'javdb_id': 'hot-id-$number',
    'movie_number': 'HOT-$number',
    'title': 'Hot movie $number',
    'cover_image': null,
    'thin_cover_image': null,
    'release_date': '2026-05-01',
    'duration_minutes': 120,
    'heat': 0,
    'is_subscribed': false,
    'can_play': false,
    'hot_actress': <String, dynamic>{'name': '女优 A'},
  };
}

void _enqueueDailyPage(
  TestApiBundle bundle, {
  required int page,
  required int start,
  required int count,
  required int total,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/daily-recommendations',
    body: <String, dynamic>{
      'items': List<Map<String, dynamic>>.generate(
        count,
        (index) => _dailyMovieJson(start + index),
      ),
      'page': page,
      'page_size': count,
      'total': total,
    },
  );
}

void _enqueueMomentPage(
  TestApiBundle bundle, {
  required int page,
  required int start,
  required int count,
  required int total,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/moment-recommendations',
    body: <String, dynamic>{
      'items': List<Map<String, dynamic>>.generate(
        count,
        (index) => _momentJson(start + index),
      ),
      'page': page,
      'page_size': count,
      'total': total,
      'generated_at': '2026-05-08T04:00:00',
    },
  );
}

Map<String, dynamic> _dailyMovieJson(int index) {
  final number = index.toString().padLeft(3, '0');
  return <String, dynamic>{
    'javdb_id': 'abc-id-$number',
    'movie_number': 'ABC-$number',
    'title': 'Movie title $number',
    'cover_image': null,
    'thin_cover_image': null,
    'release_date': '2026-05-01',
    'duration_minutes': 120,
    'heat': 88 + index,
    'is_subscribed': false,
    'can_play': true,
    'snapshot_date': '2026-05-08',
    'generated_at': '2026-05-08T04:00:00',
    'rank': index,
    'recommendation_score': 0.91,
    'reason_codes': ['popular'],
    'reason_texts': ['近期热度较高'],
    'signal_scores': <String, dynamic>{'heat': 0.8},
    'is_stale': index == 1,
  };
}

Map<String, dynamic> _momentJson(int index) {
  final number = index.toString().padLeft(3, '0');
  return <String, dynamic>{
    'recommendation_id': index,
    'rank': index,
    'score': 0.88,
    'strategy': 'visual',
    'reason': '与你收藏的时刻画面相似',
    'media_id': 100 + index,
    'thumbnail_id': 500 + index,
    'offset_seconds': 360,
    'image': null,
    'movie': <String, dynamic>{
      'javdb_id': 'abc-id-$number',
      'movie_number': 'ABC-$number',
      'title': 'Movie title $number',
      'cover_image': null,
      'thin_cover_image': null,
      'release_date': null,
      'duration_minutes': 120,
      'heat': 10 + index,
      'is_subscribed': false,
      'can_play': true,
    },
  };
}
