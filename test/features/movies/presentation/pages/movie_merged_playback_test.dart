import 'package:flutter/gestures.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_merge_playback_candidates.dart';
import 'package:sakuramedia/features/movies/presentation/pages/desktop/movie_detail_page.dart';
import 'package:sakuramedia/features/movies/presentation/pages/mobile/movie_detail_page.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_merged_play_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_merged_playback_factory_provider.dart';
import 'package:sakuramedia/routes/desktop_routes.dart' as desktop;
import 'package:sakuramedia/routes/mobile_routes.dart' as mobile_routes;
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/video/themed_video_player.dart';
import 'package:sakuramedia/widgets/domain/media/movie_player_thumbnail_panel.dart';
import 'package:sakuramedia/widgets/domain/movies/player/merged_position_indicator.dart';
import '../../../../support/test_api_bundle.dart';
import '../../../../support/test_playlist_player.dart';

class _VideoController extends Fake implements VideoController {
  _VideoController(this.player);
  @override
  final Player player;
  @override
  final notifier = ValueNotifier<PlatformVideoController?>(null);
  @override
  Future<void> get waitUntilFirstFrameRendered => Future.value();
}

Map<String, dynamic> _media(
  int id,
  int libraryId, {
  bool valid = true,
  String? url,
}) => {
  'media_id': id,
  'library_id': libraryId,
  'provider_key': 'provider-without-merge',
  'valid': valid,
  'file_name': 'TEST-001-CD$id.mkv',
  'duration_seconds': id == 1 ? 600 : 1200,
  'play_url': url ?? '/media/$id/play/file.mkv',
};

Map<String, dynamic> _movie() => {
  'movie_number': 'TEST-001',
  'title': '多段影片播放测试',
  'can_play': true,
  'media_items': [
    _media(2, 7),
    _media(1, 7),
    _media(3, 7, valid: false),
    _media(4, 8),
  ],
};

void main() {
  test('内置按同库有效可播媒体分组排序，不要求后端合并能力', () {
    final movie = MovieDetailDto.fromJson({
      ..._movie(),
      'media_items': [
        ..._movie()['media_items'] as List,
        _media(5, 7, url: ''),
        {'media_id': 6, 'play_url': '/media/6/play'},
      ],
    });
    final candidates = resolveMovieMergePlaybackCandidates(
      movie,
      useExternalPlayer: false,
    );
    expect(candidates.single.libraryId, 7);
    expect(candidates.single.segmentCount, 2);
    expect(movieMergedPlaybackMedia(movie, 7).map((media) => media.mediaId), [
      1,
      2,
    ]);
    expect(
      resolveMovieMergePlaybackCandidates(movie, useExternalPlayer: true),
      isEmpty,
    );
  });

  test('外部播放保留后端返回的候选', () {
    final movie = MovieDetailDto.fromJson({
      ..._movie(),
      'merge_playback_candidates': [
        {
          'library_id': 7,
          'library_name': '本地库',
          'provider_key': 'local',
          'segment_count': 2,
        },
      ],
    });
    expect(
      resolveMovieMergePlaybackCandidates(movie, useExternalPlayer: true),
      same(movie.mergePlaybackCandidates),
    );
  });

  testWidgets('分段失效后展示错误，重试重新读取媒体并恢复播放', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final messenger = tester.binding.defaultBinaryMessenger;
    const channel = MethodChannel('com.alexmercerind/media_kit_video');
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final session = SessionStore.inMemory();
    await session.saveBaseUrl('https://api.example.com');
    final bundle = await createTestApiBundle(session);
    addTearDown(bundle.dispose);
    addTearDown(session.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies/TEST-001',
      body: {
        ..._movie(),
        'media_items': [_media(1, 7), _media(2, 7, valid: false)],
      },
    );
    final native = TestPlaylistPlayer();
    final player = Player(platformPlayer: native);
    final controller = _VideoController(player);
    addTearDown(controller.notifier.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...bundle.riverpodOverrides(),
          movieMergedPlaybackFactoryProvider.overrideWithValue(
            () => (player: player, videoController: controller),
          ),
        ],
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const MovieMergedPlayContent(
            movieNumber: 'TEST-001',
            libraryId: 7,
            fallbackPath: '/',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('该媒体库没有足够的可播放分段'), findsOneWidget);
    expect(native.calls, isEmpty);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies/TEST-001',
      body: _movie(),
    );
    for (final id in [1, 2]) {
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media/$id/thumbnails',
        body: [],
      );
    }
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.byType(ThemedVideoPlayer), findsOneWidget);
    expect(native.state.playlist.medias, hasLength(2));
    expect(bundle.adapter.hitCount('GET', '/movies/TEST-001'), 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  for (final mobile in [false, true]) {
    for (final external in [false, true]) {
      testWidgets('${mobile ? '移动' : '桌面'}详情合并入口使用${external ? '外部' : '内置'}播放器', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = mobile
            ? TargetPlatform.android
            : TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = mobile
            ? const Size(390, 844)
            : const Size(1100, 760);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        SharedPreferences.setMockInitialValues(
          external
              ? {
                  mobile
                          ? 'android.external_player.package_name'
                          : 'macos.external_player.application_path':
                      'test-player',
                }
              : {},
        );
        final messenger = tester.binding.defaultBinaryMessenger;
        const videoChannel = MethodChannel('com.alexmercerind/media_kit_video');
        const externalChannel = MethodChannel('sakuramedia/external_player');
        messenger.setMockMethodCallHandler(videoChannel, (_) async => null);
        Map? externalArgs;
        messenger.setMockMethodCallHandler(externalChannel, (call) async {
          externalArgs = call.arguments as Map;
          return true;
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(videoChannel, null);
          messenger.setMockMethodCallHandler(externalChannel, null);
        });
        final session = SessionStore.inMemory();
        await session.saveBaseUrl('https://api.example.com');
        await session.saveTokens(
          accessToken: 'test',
          refreshToken: 'test',
          expiresAt: DateTime(2030),
        );
        final bundle = await createTestApiBundle(session);
        addTearDown(bundle.dispose);
        addTearDown(session.dispose);
        final data = _movie();
        if (external) {
          data['merge_playback_candidates'] = [
            {
              'library_id': 7,
              'library_name': '测试库',
              'provider_key': 'local',
              'segment_count': 2,
            },
          ];
          bundle.adapter.enqueueJson(
            method: 'GET',
            path: '/movies/TEST-001/merged-playback',
            body: {'play_url': '/media/merged/play/stream.mp4?signature=test'},
          );
        }
        bundle.adapter.enqueueJson(
          method: 'GET',
          path: '/movies/TEST-001',
          body: data,
        );
        bundle.adapter.enqueueJson(
          method: 'GET',
          path: '/media-libraries',
          body: [],
        );
        bundle.adapter.enqueueJson(
          method: 'GET',
          path: '/movies/TEST-001/similar',
          body: {'items': []},
        );
        final native = TestPlaylistPlayer();
        final player = Player(platformPlayer: native);
        final controller = _VideoController(player);
        addTearDown(controller.notifier.dispose);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: mobile
                    ? const MobileMovieDetailPage(movieNumber: 'TEST-001')
                    : const DesktopMovieDetailPage(movieNumber: 'TEST-001'),
              ),
            ),
            mobile
                ? mobile_routes.$mobileMoviePlayerRouteData
                : desktop.$desktopMoviePlayerRouteData,
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...bundle.riverpodOverrides(),
              movieMergedPlaybackFactoryProvider.overrideWithValue(
                () => (player: player, videoController: controller),
              ),
            ],
            child: OKToast(
              child: AppPlatformScope(
                platform: mobile ? AppPlatform.mobile : AppPlatform.desktop,
                child: MaterialApp.router(
                  theme: mobile ? sakuraMobileThemeData : sakuraThemeData,
                  routerConfig: router,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final mergeButton = find.byKey(
          const Key('movie-detail-merge-playback-button'),
        );
        expect(mergeButton, findsOneWidget);
        expect(find.text('合并播放 · 2 段'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (!external) {
          bundle.adapter.enqueueJson(
            method: 'GET',
            path: '/movies/TEST-001',
            body: data,
          );
          for (final id in [1, 2]) {
            bundle.adapter.enqueueJson(
              method: 'GET',
              path: '/media/$id/thumbnails',
              body: [
                {
                  'thumbnail_id': id,
                  'media_id': id,
                  'offset_seconds': 30,
                  'image': {},
                },
              ],
            );
          }
        }
        await tester.ensureVisible(mergeButton);
        await tester.tap(mergeButton);
        await tester.pumpAndSettle();
        if (external) {
          expect(externalArgs?['playerId'], 'test-player');
          expect(
            externalArgs?['url'],
            'https://api.example.com/media/merged/play/stream.mp4?signature=test',
          );
          expect(find.byType(MovieMergedPlayContent), findsNothing);
          expect(native.calls, isEmpty);
        } else {
          expect(find.byType(MovieMergedPlayContent), findsOneWidget);
          expect(externalArgs, isNull);
          expect(native.state.playlist.medias.map((media) => media.uri), [
            'https://api.example.com/media/1/play/file.mkv',
            'https://api.example.com/media/2/play/file.mkv',
          ]);
          expect(
            bundle.adapter.hitCount('GET', '/movies/TEST-001/merged-playback'),
            0,
          );
          tester.view.physicalSize = mobile
              ? const Size(844, 390)
              : const Size(1100, 760);
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 3));
          ThemedVideoPlayer surface() => tester.widget<ThemedVideoPlayer>(
            find.byType(ThemedVideoPlayer, skipOffstage: false),
          );
          final progress = surface().bottomControls
              .whereType<MergedPositionIndicator>()
              .single;
          expect(progress.episodeDurationsSeconds, [600, 1200]);
          progress.onSeekGlobalSeconds(750);
          await tester.pumpAndSettle();
          expect(native.state.playlist.index, 1);
          native.select(1, const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(native.calls, contains('seek:150'));
          final panel = tester.widget<MoviePlayerThumbnailPanel>(
            find.byType(MoviePlayerThumbnailPanel),
          );
          expect(panel.thumbnails.map((frame) => frame.mediaId), [1, 2]);
          panel.onThumbnailTap(0);
          await tester.pumpAndSettle();
          expect(native.state.playlist.index, 0);
          native.select(0, const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(native.calls, contains('seek:30'));
          Future<void> openFrameMenu({
            List<Map<String, dynamic>> points = const [],
          }) async {
            bundle.adapter.enqueueJson(
              method: 'GET',
              path: '/media/2/points',
              body: points,
            );
            final frame = find.byKey(const Key('movie-player-thumb-1'));
            if (mobile) {
              await tester.longPress(frame);
            } else {
              await tester.tap(frame, buttons: kSecondaryMouseButton);
            }
            await tester.pumpAndSettle();
            expect(find.text('相似图片'), findsOneWidget);
            expect(find.text('保存到本地'), findsOneWidget);
            expect(find.text('播放'), findsOneWidget);
            if (mobile) {
              expect(
                find.byWidgetPredicate(
                  (widget) => widget.runtimeType.toString() ==
                      '_PopupMenu<AppImageActionType>',
                ),
                findsOneWidget,
              );
            }
          }

          await openFrameMenu();
          await tester.tap(find.text('播放'));
          await tester.pumpAndSettle();
          native.select(1, const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(native.state.playlist.index, 1);
          expect(native.state.position.inSeconds, 30);
          expect(native.calls.last, 'seek:30');
          final point = {
            'point_id': 22,
            'media_id': 2,
            'thumbnail_id': 2,
            'offset_seconds': 30,
          };
          await openFrameMenu();
          bundle.adapter.enqueueJson(
            method: 'POST',
            path: '/media/2/points',
            body: point,
          );
          await tester.tap(find.text('添加标记'));
          await tester.pumpAndSettle();
          expect(bundle.adapter.hitCount('POST', '/media/2/points'), 1);
          await openFrameMenu(points: [point]);
          bundle.adapter.enqueueJson(
            method: 'DELETE',
            path: '/media/2/points/22',
            statusCode: 204,
          );
          await tester.tap(find.text('删除标记'));
          await tester.pumpAndSettle();
          expect(bundle.adapter.hitCount('DELETE', '/media/2/points/22'), 1);

          if (mobile) {
            surface().bottomControls
                .whereType<MaterialCustomButton>()
                .single
                .onPressed();
          } else {
            surface().bottomControls
                .whereType<MaterialDesktopCustomButton>()
                .single
                .onPressed();
          }
          await tester.pumpAndSettle();
          expect(find.text('选集 · 2'), findsOneWidget);
          await tester.tap(find.byKey(const Key('movie-merged-episode-1')));
          await tester.pumpAndSettle();
          expect(native.state.playlist.index, 1);
          expect(find.text('选集 · 2'), findsNothing);
          final videoState = tester.state<VideoState>(find.byType(Video).first);
          await videoState.enterFullscreen();
          await tester.pumpAndSettle();
          if (mobile) {
            surface().bottomControls
                .whereType<MaterialCustomButton>()
                .single
                .onPressed();
          } else {
            surface().bottomControls
                .whereType<MaterialDesktopCustomButton>()
                .single
                .onPressed();
          }
          await tester.pumpAndSettle();
          expect(
            tester
                .getRect(find.byKey(const Key('episode-selector-list')))
                .right,
            tester.view.physicalSize.width,
          );
          await tester.tap(find.byKey(const Key('movie-merged-episode-0')));
          await tester.pumpAndSettle();
          expect(native.state.playlist.index, 0);
          await videoState.exitFullscreen();
          await tester.pumpAndSettle();
          native.select(0, const Duration(seconds: 590));
          await tester.pumpAndSettle();
          native.select(1, const Duration(seconds: 35));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<MoviePlayerThumbnailPanel>(
                  find.byType(MoviePlayerThumbnailPanel),
                )
                .activeIndex,
            1,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
