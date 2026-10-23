import 'dart:async';

import 'package:dio/dio.dart' show ResponseBody;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/pages/desktop/movie_detail_page.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_detail_page_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';

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

  Future<void> pumpPage(
    WidgetTester tester, {
    AppPageRefreshRegistrar? refreshRegistrar,
    TargetPlatform? platform,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const page = DesktopMovieDetailPage(movieNumber: 'ABC-001');
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: platform == null
                ? sakuraThemeData
                : sakuraThemeData.copyWith(platform: platform),
            home: Scaffold(
              body: refreshRegistrar == null
                  ? page
                  : AppPageRefreshRegistrarScope(
                      registrar: refreshRegistrar,
                      child: page,
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desktop movie detail page loads and renders movie info', (
    WidgetTester tester,
  ) async {
    _enqueueMovieDetailResponses(bundle);

    await pumpPage(tester);

    expect(find.text('Movie 1'), findsOneWidget);
    expect(
      find.byKey(const Key('movie-detail-hero-overlay-title')),
      findsOneWidget,
    );
    final content = tester.widget<MovieDetailPageContent>(
      find.byType(MovieDetailPageContent),
    );
    expect(content.surfaceColor, sakuraThemeData.appColors.surfaceElevated);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面详情页不再注册顶栏刷新回调', (WidgetTester tester) async {
    _enqueueMovieDetailResponses(bundle);
    final registered = <AppPageRefreshCallback>[];

    await pumpPage(
      tester,
      refreshRegistrar: AppPageRefreshRegistrar(
        register: registered.add,
        unregister: registered.remove,
      ),
    );

    expect(registered, isEmpty);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面详情页顶部不能下拉，底部上滑仍可过卷', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      _enqueueMovieDetailResponses(bundle);

      await pumpPage(tester, platform: TargetPlatform.macOS);

      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(MovieDetailPageContent.scrollViewKey),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      final scrollCenter = tester.getCenter(
        find.byKey(MovieDetailPageContent.scrollViewKey),
      );

      final pullDown = await tester.startGesture(scrollCenter);
      await pullDown.moveBy(const Offset(0, 300));
      await tester.pump();
      expect(position.pixels, 0);
      expect(position.outOfRange, isFalse);
      await pullDown.up();
      await tester.pumpAndSettle();
      expect(position.pixels, 0);

      // 底部上滑的过卷手感保留。
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final pushUp = await tester.startGesture(scrollCenter);
      await pushUp.moveBy(const Offset(0, -240));
      await tester.pump();
      expect(position.pixels, greaterThan(position.maxScrollExtent));
      await pushUp.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('playlist edits update the detail summary when closed', (
    tester,
  ) async {
    _enqueueMovieDetailResponses(
      bundle,
      playlists: [
        {'id': 1, 'name': '周末待看', 'kind': 'custom', 'is_system': false},
      ],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/playlists',
      body: [
        {'id': 1, 'name': '周末待看', 'kind': 'custom', 'is_system': false},
      ],
    );
    bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/playlists/1/movies/ABC-001',
      statusCode: 204,
    );
    await pumpPage(tester);
    expect(find.text('周末待看'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('movie-detail-playlist-trigger')),
    );
    await tester.tap(find.byKey(const Key('movie-detail-playlist-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movie-playlist-option-1')));
    await tester.pumpAndSettle();
    _enqueueMovieDetailResponses(bundle);
    Navigator.of(
      tester.element(find.byKey(const Key('movie-playlist-option-1'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('周末待看'), findsNothing);
    expect(find.byTooltip('加入播放列表'), findsOneWidget);
    expect(bundle.adapter.hitCount('DELETE', '/playlists/1/movies/ABC-001'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面详情页收藏影片走 hero 快捷键', (WidgetTester tester) async {
    final favoriteGate = Completer<void>();
    _enqueueMovieDetailResponses(bundle, favoritePlaylistId: 9);
    bundle.adapter.enqueueResponder(
      method: 'PUT',
      path: '/playlists/9/movies/ABC-001',
      responder: (_, _) async {
        await favoriteGate.future;
        return ResponseBody.fromBytes(const <int>[], 204);
      },
    );
    _enqueueMovieDetailResponses(bundle, favoritePlaylistId: 9);

    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('movie-detail-hero-favorite-icon')));
    await tester.pump();

    // 收藏只让收藏键转圈，更多键不跟着加载。
    expect(
      find.byKey(const Key('movie-detail-hero-favorite-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-detail-hero-more-actions-loading')),
      findsNothing,
    );

    favoriteGate.complete();
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('PUT', '/playlists/9/movies/ABC-001'), 1);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('收藏后失效收藏列表 provider，返回列表会重新拉取', (WidgetTester tester) async {
    _enqueueMovieDetailResponses(bundle, favoritePlaylistId: 9);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/9/movies',
      body: <String, dynamic>{
        'items': const <Map<String, dynamic>>[],
        'page': 1,
        'page_size': 24,
        'total': 0,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/playlists/9/movies/ABC-001',
      statusCode: 204,
    );
    _enqueueMovieDetailResponses(bundle, favoritePlaylistId: 9);

    await pumpPage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DesktopMovieDetailPage)),
    );
    const playlistScope = MovieSummaryScope.playlist(playlistId: 9);
    final subscription = container.listen(
      movieSummaryProvider(playlistScope),
      (_, _) {},
    );
    addTearDown(subscription.close);
    container.read(movieSummaryProvider(playlistScope));
    await tester.pumpAndSettle();

    int playlistRequests() => bundle.adapter.requests
        .where((request) => request.uri.path == '/playlists/9/movies')
        .length;
    final before = playlistRequests();

    // 失效后的重拉需要一条新的响应。
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/9/movies',
      body: <String, dynamic>{
        'items': const <Map<String, dynamic>>[],
        'page': 1,
        'page_size': 24,
        'total': 0,
      },
    );
    await tester.tap(find.byKey(const Key('movie-detail-hero-favorite-icon')));
    await tester.pumpAndSettle();

    expect(playlistRequests(), before + 1);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('桌面详情页从更多菜单打开磁力搜索', (WidgetTester tester) async {
    _enqueueMovieDetailResponses(bundle);

    await pumpPage(tester);

    await tester.ensureVisible(
      find.byKey(const Key('movie-detail-hero-more-actions-button')),
    );
    await tester.tap(
      find.byKey(const Key('movie-detail-hero-more-actions-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movie-detail-hero-action-openMagnetSearch')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-detail-inspector-panel')),
      findsOneWidget,
    );
    expect(find.text('磁力搜索'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a clip opens the actions dialog instead of playing', (
    WidgetTester tester,
  ) async {
    _enqueueMovieDetailResponses(bundle);
    _enqueueMovieClips(bundle);

    await pumpPage(tester);

    // 正文区块按需构建：切片在首屏下方，先滚到视口内再对齐到完全可见。
    final clipCard = find.byKey(const Key('movie-clip-strip-card-1'));
    await tester.scrollUntilVisible(
      clipCard,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(clipCard);
    await tester.pumpAndSettle();
    await tester.tap(clipCard);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-detail-clip-action-play')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-detail-clip-action-rename')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not expose a playback delivery switch', (
    WidgetTester tester,
  ) async {
    _enqueueMovieDetailResponses(bundle);

    await pumpPage(tester);

    expect(
      find.byKey(const Key('movie-media-playback-delivery-selector')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('movie-media-playback-delivery-switch')),
      findsNothing,
    );
  });
}

void _enqueueMovieDetailResponses(
  TestApiBundle bundle, {
  List<Map<String, dynamic>> playlists = const [],
  int? favoritePlaylistId,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/ABC-001',
    body: <String, dynamic>{
      'playlists': playlists,
      'favorite_playlist_id': favoritePlaylistId,
      'javdb_id': 'MovieA1',
      'movie_number': 'ABC-001',
      'title': 'Movie 1',
      'cover_image': null,
      'release_date': '2024-01-02',
      'duration_minutes': 120,
      'score': 4.5,
      'watched_count': 12,
      'want_watch_count': 23,
      'comment_count': 34,
      'score_number': 45,
      'is_collection': false,
      'is_subscribed': true,
      'can_play': true,
      'series_id': 7,
      'series_name': 'Attackers',
      'summary': '',
      'actors': const <Map<String, dynamic>>[],
      'tags': const <Map<String, dynamic>>[],
      'thin_cover_image': null,
      'plot_images': const <Map<String, dynamic>>[],
      'media_items': const <Map<String, dynamic>>[
        <String, dynamic>{
          'media_id': 1,
          'play_url': '/media/ABC-001.mp4',
          'file_name': 'ABC-001.mp4',
          'valid': true,
          'points': <Map<String, dynamic>>[],
        },
      ],
    },
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/media-libraries',
    body: const <Map<String, dynamic>>[],
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/ABC-001/similar',
    body: const <String, dynamic>{'items': <dynamic>[]},
  );
}

void _enqueueMovieClips(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/media-clips',
    body: <String, dynamic>{
      'items': const <Map<String, dynamic>>[
        <String, dynamic>{
          'clip_id': 1,
          'media_id': 1,
          'movie_number': 'ABC-001',
          'start_offset_seconds': 120,
          'end_offset_seconds': 300,
          'title': '精彩片段',
          'duration_seconds': 180,
          'file_size_bytes': 15728640,
          'cover_image': null,
          'stream_url': '/media-clips/1/stream',
        },
      ],
    },
  );
}
