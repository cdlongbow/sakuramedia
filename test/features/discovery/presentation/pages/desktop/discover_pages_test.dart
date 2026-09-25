import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/discovery/presentation/desktop_discover_page.dart';
import 'package:sakuramedia/features/discovery/presentation/pages/desktop/discover_moments_page.dart';
import 'package:sakuramedia/features/discovery/presentation/pages/desktop/discover_movies_page.dart';
import 'package:sakuramedia/features/discovery/presentation/pages/desktop/hot_actress_releases_page.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/subscription_heart_badge.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets(
    'desktop discover page keeps followed actresses and adds hot releases',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueDiscoveryResponses(bundle);
      _enqueueSubscription(bundle, movieNumber: 'HOT-001');

      await _pumpDiscoveryWidget(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('desktop-discover-page')), findsOneWidget);
      expect(find.text('DISCOVERY'), findsNothing);
      expect(find.text('读取后端最新推荐快照，集中展示今日推荐影片和推荐时刻。'), findsNothing);
      expect(
        find.byKey(const Key('desktop-discover-summary-card')),
        findsNothing,
      );
      // 女优上新、热门新片、今日推荐各一个影片网格。
      expect(find.byKey(const Key('movie-summary-grid')), findsNWidgets(3));
      expect(find.text('女优上新'), findsOneWidget);
      expect(
        find.byKey(const Key('movie-summary-card-FOL-001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('desktop-discover-load-more-follow')),
        findsOneWidget,
      );
      expect(find.text('热门新片'), findsOneWidget);
      expect(
        find.byKey(const Key('movie-summary-card-HOT-001')),
        findsOneWidget,
      );
      expect(find.text('热门：女优 1'), findsOneWidget);
      expect(
        find.byKey(const Key('desktop-discover-load-more-hot-actress')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movie-summary-card-ABC-001')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('moment-grid')), findsOneWidget);
      expect(find.byKey(const Key('moment-card-1')), findsOneWidget);
      expect(
        find.byKey(const Key('desktop-discover-load-more-daily')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('desktop-discover-load-more-moments')),
        findsOneWidget,
      );
      final requestsByPath = {
        for (final request in bundle.adapter.requests) request.path: request,
      };
      expect(
        requestsByPath['/hot-actress-releases']!
            .uri
            .queryParameters['page_size'],
        '24',
      );
      expect(
        requestsByPath['/movies/subscribed-actors/latest']!
            .uri
            .queryParameters['page_size'],
        '24',
      );
      expect(
        requestsByPath['/daily-recommendations']!
            .uri
            .queryParameters['page_size'],
        '24',
      );
      expect(
        requestsByPath['/moment-recommendations']!
            .uri
            .queryParameters['page_size'],
        '24',
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

  testWidgets('desktop discover movies page loads more on scroll', (
    tester,
  ) async {
    final sessionStore = await _buildSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueDailyPage(bundle, page: 1, start: 1, count: 24, total: 25);
    _enqueueDailyPage(bundle, page: 2, start: 25, count: 1, total: 25);

    await _pumpDiscoveryWidget(
      tester,
      sessionStore: sessionStore,
      bundle: bundle,
      child: const DesktopDiscoverMoviesPage(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('desktop-discover-movies-page')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('movie-summary-card-ABC-001')), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-summary-card-ABC-025')), findsOneWidget);
  });

  testWidgets('desktop hot actress releases page loads more on scroll', (
    tester,
  ) async {
    final sessionStore = await _buildSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueHotActressPage(bundle, page: 1, start: 1, count: 24, total: 25);
    _enqueueHotActressPage(bundle, page: 2, start: 25, count: 1, total: 25);
    _enqueueSubscription(bundle, movieNumber: 'HOT-001');

    await _pumpDiscoveryWidget(
      tester,
      sessionStore: sessionStore,
      bundle: bundle,
      child: const DesktopHotActressReleasesPage(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('desktop-hot-actress-releases-page')),
      findsOneWidget,
    );
    expect(find.text('热门：女优 1'), findsOneWidget);

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

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-summary-card-HOT-025')), findsOneWidget);
  });

  testWidgets('desktop discover moments page loads more on scroll', (
    tester,
  ) async {
    final sessionStore = await _buildSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueMomentPage(bundle, page: 1, start: 1, count: 24, total: 25);
    _enqueueMomentPage(bundle, page: 2, start: 25, count: 1, total: 25);

    await _pumpDiscoveryWidget(
      tester,
      sessionStore: sessionStore,
      bundle: bundle,
      child: const DesktopDiscoverMomentsPage(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('desktop-discover-moments-page')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('moment-card-1')), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('moment-card-25')), findsOneWidget);
  });

  testWidgets(
    'desktop discover movies page auto loads more when first page does not fill viewport',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueDailyPage(bundle, page: 1, start: 1, count: 3, total: 6);
      _enqueueDailyPage(bundle, page: 2, start: 4, count: 3, total: 6);

      await _pumpDiscoveryWidget(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMoviesPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movie-summary-card-ABC-004')), findsOneWidget);
      expect(bundle.adapter.hitCount('GET', '/daily-recommendations'), 2);
    },
  );

  testWidgets(
    'desktop hot actress releases page auto loads more when first page does not fill viewport',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueHotActressPage(bundle, page: 1, start: 1, count: 3, total: 6);
      _enqueueHotActressPage(bundle, page: 2, start: 4, count: 3, total: 6);

      await _pumpDiscoveryWidget(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopHotActressReleasesPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movie-summary-card-HOT-004')), findsOneWidget);
      expect(bundle.adapter.hitCount('GET', '/hot-actress-releases'), 2);
    },
  );

  testWidgets(
    'desktop discover moments page auto loads more when first page does not fill viewport',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueMomentPage(bundle, page: 1, start: 1, count: 3, total: 6);
      _enqueueMomentPage(bundle, page: 2, start: 4, count: 3, total: 6);

      await _pumpDiscoveryWidget(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMomentsPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('moment-card-4')), findsOneWidget);
      expect(bundle.adapter.hitCount('GET', '/moment-recommendations'), 2);
    },
  );

  testWidgets(
    'desktop discover movies page does not auto retry after short page load more error',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueDailyPage(bundle, page: 1, start: 1, count: 3, total: 6);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/daily-recommendations',
        statusCode: 500,
        body: <String, dynamic>{'detail': 'failed'},
      );

      await _pumpDiscoveryWidget(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMoviesPage(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movie-summary-card-ABC-001')), findsOneWidget);
      expect(find.text('加载更多推荐影片失败，请点击重试'), findsOneWidget);
      expect(bundle.adapter.hitCount('GET', '/daily-recommendations'), 2);
    },
  );

  testWidgets(
    'desktop recommendation moments hover exposes unified actions and resolves the real point',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueMomentPage(bundle, page: 1, start: 1, count: 1, total: 1);
      _enqueueRecommendationPoint(
        bundle,
        mediaId: 101,
        thumbnailId: 501,
        pointId: 99,
      );
      _enqueueMomentCollectionsResponse(bundle);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media-points/99/collections',
        body: const <Map<String, dynamic>>[],
      );
      bundle.adapter.enqueueJson(
        method: 'PUT',
        path: '/moment-collections/7/points/99',
        statusCode: 204,
      );

      await _pumpDiscoveryRouter(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMomentsPage(),
      );
      await tester.pumpAndSettle();

      await _hoverMomentCard(tester, 1);

      // 与「全部时刻」同一张卡：播放 / 影片 / 加入合集；推荐条目没有真实
      // 时刻 ID，不提供删除。
      expect(find.byKey(const Key('moment-card-play-1')), findsOneWidget);
      expect(find.byKey(const Key('moment-card-movie-1')), findsOneWidget);
      expect(
        find.byKey(const Key('moment-card-add-collection-1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('moment-card-delete-1')), findsNothing);

      await tester.tap(find.byKey(const Key('moment-card-add-collection-1')));
      await tester.pumpAndSettle();

      // 推荐 ID 不直接进合集：先用 mediaId + thumbnailId 反查真实时刻。
      expect(bundle.adapter.hitCount('GET', '/media/101/points'), 1);
      expect(
        find.byKey(const Key('add-to-moment-collection-list')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('add-to-moment-collection-7')));
      await tester.pumpAndSettle();

      expect(
        bundle.adapter.hitCount('PUT', '/moment-collections/7/points/99'),
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'desktop recommendation moments hover movie opens the source movie',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueMomentPage(bundle, page: 1, start: 1, count: 1, total: 1);

      await _pumpDiscoveryRouter(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMomentsPage(),
      );
      await tester.pumpAndSettle();

      await _hoverMomentCard(tester, 1);
      await tester.tap(find.byKey(const Key('moment-card-movie-1')));
      await tester.pumpAndSettle();

      expect(find.text('movie-detail'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop recommendation preview opens the movie from the cover',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueMomentPage(bundle, page: 1, start: 1, count: 1, total: 1);
      _enqueueMomentPreviewMovie(bundle);
      _enqueueEmptyMediaPoints(bundle, mediaId: 101);

      await _pumpDiscoveryRouter(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMomentsPage(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('moment-card-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('image-search-result-preview-dialog')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('image-search-result-preview-movie-cover')),
      );
      await tester.pumpAndSettle();

      expect(find.text('movie-detail'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop recommendation preview opens the actor from the avatar',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueMomentPage(bundle, page: 1, start: 1, count: 1, total: 1);
      _enqueueMomentPreviewMovie(bundle);
      _enqueueEmptyMediaPoints(bundle, mediaId: 101);

      await _pumpDiscoveryRouter(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMomentsPage(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('moment-card-1')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('image-search-result-preview-actor-7')),
      );
      await tester.pumpAndSettle();

      expect(find.text('actor-detail'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop recommendation preview add-to-collection resolves the real point',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueMomentPage(bundle, page: 1, start: 1, count: 1, total: 1);
      _enqueueMomentPreviewMovie(bundle);
      // 预览打开与回执处理各反查一次真实时刻。
      _enqueueRecommendationPoint(
        bundle,
        mediaId: 101,
        thumbnailId: 501,
        pointId: 99,
      );
      _enqueueRecommendationPoint(
        bundle,
        mediaId: 101,
        thumbnailId: 501,
        pointId: 99,
      );
      _enqueueMomentCollectionsResponse(bundle);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media-points/99/collections',
        body: const <Map<String, dynamic>>[],
      );
      bundle.adapter.enqueueJson(
        method: 'PUT',
        path: '/moment-collections/7/points/99',
        statusCode: 204,
      );

      await _pumpDiscoveryRouter(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMomentsPage(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('moment-card-1')));
      await tester.pumpAndSettle();

      expect(find.text('加入合集'), findsOneWidget);
      await tester.tap(find.text('加入合集'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('add-to-moment-collection-list')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('add-to-moment-collection-7')));
      await tester.pumpAndSettle();

      expect(
        bundle.adapter.hitCount('PUT', '/moment-collections/7/points/99'),
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'desktop discover movies page keeps items after load more error',
    (tester) async {
      final sessionStore = await _buildSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueDailyPage(bundle, page: 1, start: 1, count: 24, total: 25);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/daily-recommendations',
        statusCode: 500,
        body: <String, dynamic>{'detail': 'failed'},
      );

      await _pumpDiscoveryWidget(
        tester,
        sessionStore: sessionStore,
        bundle: bundle,
        child: const DesktopDiscoverMoviesPage(),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movie-summary-card-ABC-001')), findsNothing);
      expect(
        find.byKey(const Key('movie-summary-card-ABC-024')),
        findsOneWidget,
      );
      expect(find.text('加载更多推荐影片失败，请点击重试'), findsOneWidget);
    },
  );
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
          theme: sakuraThemeData,
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

Future<void> _pumpDiscoveryRouter(
  WidgetTester tester, {
  required SessionStore sessionStore,
  required TestApiBundle bundle,
  required Widget child,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
      GoRoute(
        path: '/desktop/library/movies/:movieNumber',
        builder: (_, __) => const Scaffold(body: Text('movie-detail')),
      ),
      GoRoute(
        path: '/desktop/library/actors/:actorId',
        builder: (_, __) => const Scaffold(body: Text('actor-detail')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp.router(
          theme: sakuraThemeData,
          routerConfig: router,
        ),
      ),
    ),
  );
}

/// 把鼠标指针移到时刻卡上：桌面端信息与动作行靠悬停展开，必须用真实指针事件。
Future<void> _hoverMomentCard(WidgetTester tester, int pointId) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(
    tester.getCenter(find.byKey(Key('moment-card-$pointId'))),
  );
  await tester.pumpAndSettle();
}

void _enqueueRecommendationPoint(
  TestApiBundle bundle, {
  required int mediaId,
  required int thumbnailId,
  required int pointId,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/media/$mediaId/points',
    body: <Map<String, dynamic>>[
      <String, dynamic>{
        'point_id': pointId,
        'media_id': mediaId,
        'thumbnail_id': thumbnailId,
        'offset_seconds': 360,
        'image': null,
        'created_at': null,
      },
    ],
  );
}

void _enqueueEmptyMediaPoints(TestApiBundle bundle, {required int mediaId}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/media/$mediaId/points',
    body: const <dynamic>[],
  );
}

void _enqueueMomentCollectionsResponse(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/moment-collections',
    body: <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 7,
        'name': '周末回看',
        'description': '',
        'point_count': 3,
        'cover_image': null,
        'created_at': '2026-09-10T10:00:00Z',
        'updated_at': '2026-09-10T11:00:00Z',
      },
    ],
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
        'small': '/cover.jpg',
        'medium': '/cover.jpg',
        'large': '/cover.jpg',
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
      'actors': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 7,
          'javdb_id': 'actor-7',
          'name': '女优 A',
          'alias_name': '',
          'gender': 1,
          'is_subscribed': false,
          'profile_image': null,
        },
      ],
      'tags': const <Map<String, dynamic>>[],
      'media_items': const <Map<String, dynamic>>[],
    },
  );
}

void _enqueueDiscoveryResponses(TestApiBundle bundle) {
  _enqueueFollowPage(bundle);
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

void _enqueueFollowPage(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/subscribed-actors/latest',
    body: {
      'items': [_followMovieJson()],
      'page': 1,
      'page_size': 24,
      'total': 1,
    },
  );
}

Map<String, dynamic> _followMovieJson() => {
  'javdb_id': 'MovieFOL-001',
  'movie_number': 'FOL-001',
  'title': 'Movie FOL-001',
  'cover_image': null,
  'release_date': '2026-05-01',
  'duration_minutes': 120,
  'is_subscribed': true,
  'can_play': true,
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
    'hot_actress': <String, dynamic>{'name': '女优 $index'},
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
