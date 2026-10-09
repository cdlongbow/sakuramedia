import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/pages/desktop/movie_player_page.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/video/player_app_fullscreen.dart';

import '../../../../../support/test_api_bundle.dart';

/// 回归测试：JAV 单片页进/退应用内全屏不得重建播放面。
///
/// 背景：外框曾用 `fullscreen ? ColoredBox : DecoratedBox`（同 key 不同类型），
/// Flutter 会把子树整个 unmount 重建，`MoviePlayerSurface` 内的 Player 被
/// dispose 后重新 open，表现为进/退全屏都从头播放。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('toggling app fullscreen keeps player surface state alive', (
    tester,
  ) async {
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies/ABC-001',
      body: _movieDetailJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/media/100/thumbnails',
      body: const <Map<String, dynamic>>[],
    );
    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/media/100/progress',
      body: <String, dynamic>{
        'media_id': 100,
        'last_position_seconds': 0,
        'last_watched_at': '2026-03-12T14:00:00',
      },
    );

    final lifecycle = _SurfaceLifecycle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraThemeData,
          home: DesktopMoviePlayerPage(
            movieNumber: 'ABC-001',
            surfaceBuilder: (
              context,
              resolvedUrl,
              surfaceController,
              initialPosition,
              resumePosition,
              onResumePromptResolved,
              onPositionChanged,
              onPlayingChanged,
              subtitleState,
              onSubtitleSelectionChanged,
              onSubtitleReloadRequested,
              onBackPressed,
              useTouchOptimizedControls,
            ) {
              return _FakePlayerSurface(lifecycle: lifecycle);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 播放面已挂载一次。
    expect(lifecycle.initCount, 1);
    expect(lifecycle.disposeCount, 0);
    expect(
      find.byKey(const Key('movie-player-thumbnail-panel')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);

    // 进全屏：图标切换，播放面不得重建，右侧面板仍在。
    await tester.tap(find.byType(PlayerAppFullscreenButton));
    // 按钮在双击手势区内：单击需越过双击超时才落定，真机上由真实时间推进，
    // 单测里用 pump 推进假时间（只 pumpAndSettle 会因无待处理帧而提前返回）。
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    expect(lifecycle.initCount, 1);
    expect(lifecycle.disposeCount, 0);
    expect(find.byType(_FakePlayerSurface), findsOneWidget);
    expect(
      find.byKey(const Key('movie-player-thumbnail-panel')),
      findsOneWidget,
    );

    // 退全屏：同样不得重建。
    await tester.tap(find.byType(PlayerAppFullscreenButton));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    expect(lifecycle.initCount, 1);
    expect(lifecycle.disposeCount, 0);
    expect(find.byType(_FakePlayerSurface), findsOneWidget);
    expect(
      find.byKey(const Key('movie-player-thumbnail-panel')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _SurfaceLifecycle {
  int initCount = 0;
  int disposeCount = 0;
}

/// 占位播放面：带全屏按钮（复用页面提供的 scope）+ 可观测的 State 生命周期。
class _FakePlayerSurface extends StatefulWidget {
  const _FakePlayerSurface({required this.lifecycle});

  final _SurfaceLifecycle lifecycle;

  @override
  State<_FakePlayerSurface> createState() => _FakePlayerSurfaceState();
}

class _FakePlayerSurfaceState extends State<_FakePlayerSurface> {
  @override
  void initState() {
    super.initState();
    widget.lifecycle.initCount++;
  }

  @override
  void dispose() {
    widget.lifecycle.disposeCount++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Row(
            children: [
              // ignore: avoid_const_literals_in_speculative_builds
              PlayerAppFullscreenButton(),
            ],
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> _movieDetailJson() {
  return <String, dynamic>{
    'javdb_id': 'MovieA1',
    'movie_number': 'ABC-001',
    'title': 'Movie 1',
    'cover_image': null,
    'release_date': '2026-03-08',
    'duration_minutes': 120,
    'score': 4.5,
    'watched_count': 12,
    'want_watch_count': 23,
    'comment_count': 34,
    'score_number': 45,
    'is_collection': false,
    'is_subscribed': true,
    'can_play': true,
    'summary': '',
    'plot_images': const <Map<String, dynamic>>[],
    'actors': const <Map<String, dynamic>>[],
    'tags': const <Map<String, dynamic>>[],
    'playlists': const <Map<String, dynamic>>[],
    'media_items': <Map<String, dynamic>>[
      <String, dynamic>{
        'media_id': 100,
        'library_id': 1,
        'play_url': '/files/media/movies/ABC-001/video.mp4',
        'provider_key': 'filesystem',
        'file_name': 'ABC-001.mp4',
        'resolution': '1920x1080',
        'file_size_bytes': 1024,
        'duration_seconds': 7200,
        'valid': true,
        'progress': null,
        'points': const <Map<String, dynamic>>[],
        'playback_deliveries': const <String>['proxy'],
      },
    ],
  };
}
