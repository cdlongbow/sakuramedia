import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_detail_action_copy.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_detail_action_menu.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_detail_action_support.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';
import 'package:sakuramedia/l10n/app_localizations_en.dart';
import 'package:sakuramedia/l10n/app_localizations_zh.dart';

import '../../../../support/fake_http_client_adapter.dart';

/// 中日韩统一表意文字，用于判定「英文界面漏出中文」。
final RegExp _cjk = RegExp(r'[\u4e00-\u9fff]');

String _labelOf(
  List<MovieDetailActionDescriptor> actions,
  MovieDetailActionType type,
) {
  return actions.firstWhere((action) => action.type == type).label;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'buildMovieDetailActionDescriptors keeps action order and prerequisites',
    () {
      final actions = buildMovieDetailActionDescriptors(
        l10n: AppLocalizationsZh(),
        isSubscribed: false,
        isCollection: false,
        isBlacklisted: false,
      );

      expect(actions.map((action) => action.type), <MovieDetailActionType>[
        MovieDetailActionType.toggleSubscription,
        MovieDetailActionType.openMagnetSearch,
        MovieDetailActionType.toggleCollectionType,
        MovieDetailActionType.toggleBlacklist,
        MovieDetailActionType.refreshMetadata,
        MovieDetailActionType.recomputeHeat,
      ]);
      expect(
        actions
            .firstWhere(
              (action) =>
                  action.type == MovieDetailActionType.toggleCollectionType,
            )
            .label,
        isNotEmpty,
      );

      final blacklistedActions = buildMovieDetailActionDescriptors(
        l10n: AppLocalizationsZh(),
        isSubscribed: false,
        isCollection: true,
        isBlacklisted: true,
      );
      expect(
        blacklistedActions.map((action) => action.type),
        isNot(contains(MovieDetailActionType.toggleSubscription)),
      );
      // 合集 / 单体、屏蔽 / 取消屏蔽是两种不同意图，文案必须能区分。
      expect(
        _labelOf(blacklistedActions, MovieDetailActionType.toggleCollectionType),
        isNot(
          _labelOf(actions, MovieDetailActionType.toggleCollectionType),
        ),
      );
      expect(
        _labelOf(blacklistedActions, MovieDetailActionType.toggleBlacklist),
        isNot(_labelOf(actions, MovieDetailActionType.toggleBlacklist)),
      );
    },
  );

  test('buildMovieDetailActionDescriptors follows the caller locale', () {
    final en = buildMovieDetailActionDescriptors(
      l10n: AppLocalizationsEn(),
      isSubscribed: false,
      isCollection: false,
      isBlacklisted: false,
      canCast: true,
    );
    final zh = buildMovieDetailActionDescriptors(
      l10n: AppLocalizationsZh(),
      isSubscribed: false,
      isCollection: false,
      isBlacklisted: false,
      canCast: true,
    );

    // 英文界面不得出现中文：操作菜单曾经整段硬编码中文。
    for (final action in en) {
      expect(_cjk.hasMatch(action.label), isFalse);
    }
    expect(
      en.map((action) => action.label),
      isNot(zh.map((action) => action.label)),
    );
  });

  test(
    'buildMovieDetailActionDescriptors prepends cast action when enabled',
    () {
      final actions = buildMovieDetailActionDescriptors(
        l10n: AppLocalizationsZh(),
        isSubscribed: false,
        isCollection: false,
        isBlacklisted: false,
        canCast: true,
      );

      expect(actions.first.type, MovieDetailActionType.castToDevice);
      expect(actions.first.label, isNotEmpty);
    },
  );

  test('buildMovieDetailActionDescriptors shows casting label when active', () {
    final actions = buildMovieDetailActionDescriptors(
      l10n: AppLocalizationsZh(),
      isSubscribed: false,
      isCollection: false,
      isBlacklisted: false,
      castSessionLabel: 'Living room TV',
    );

    expect(actions.first.type, MovieDetailActionType.castToDevice);
    // 正在投屏时优先显示调用方给的会话名，而不是通用「投屏到电视」。
    expect(actions.first.label, 'Living room TV');
  });

  test(
    'movieDetailRemoteActionSpecFor has no remote spec for local actions',
    () {
      for (final action in [
        MovieDetailActionType.toggleCollectionType,
        MovieDetailActionType.openMagnetSearch,
      ]) {
        expect(
          movieDetailRemoteActionSpecFor(
            action: action,
            movieNumber: 'ABC-001',
            l10n: AppLocalizationsZh(),
          ),
          isNull,
        );
      }
    },
  );

  test('movieDetailRemoteActionSpecFor maps refresh metadata action', () async {
    final spec = await _runRemoteActionSpec(
      action: MovieDetailActionType.refreshMetadata,
      expectedPath: '/movies/ABC-001/metadata-refresh',
    );

    expect(spec.successMessage, '影片元数据已刷新');
    expect(spec.failureMessage, '刷新影片元数据失败');
    expect(spec.resetPreview, isTrue);
  });

  test('movieDetailRemoteActionSpecFor maps recompute heat action', () async {
    final spec = await _runRemoteActionSpec(
      action: MovieDetailActionType.recomputeHeat,
      expectedPath: '/movies/ABC-001/heat-recompute',
    );

    expect(spec.successMessage, '影片热度重算任务已提交，请在活动中心查看进度');
    expect(spec.failureMessage, '计算影片热度失败');
    expect(spec.resetPreview, isFalse);
  });

  testWidgets(
    'applyReturnedMovieDetail keeps selected media when still present',
    (WidgetTester tester) async {
      final result = await _runApplyReturnedMovieDetail(
        tester,
        movie: _movieDetail(mediaIds: const <int>[10, 20]),
        selectedMediaId: 20,
      );

      expect(result.selectedMediaId, 20);
      expect(result.isSubscribedOverride, isNull);
      expect(result.isCollectionOverride, isNull);
    },
  );

  testWidgets(
    'applyReturnedMovieDetail falls back to first media when selection disappears',
    (WidgetTester tester) async {
      final result = await _runApplyReturnedMovieDetail(
        tester,
        movie: _movieDetail(mediaIds: const <int>[30, 40]),
        selectedMediaId: 20,
      );

      expect(result.selectedMediaId, 30);
    },
  );

  testWidgets(
    'applyReturnedMovieDetail clears selection when no media remain',
    (WidgetTester tester) async {
      final result = await _runApplyReturnedMovieDetail(
        tester,
        movie: _movieDetail(mediaIds: const <int>[]),
        selectedMediaId: 20,
      );

      expect(result.selectedMediaId, isNull);
    },
  );

  testWidgets(
    'resolveMovieSubscriptionNotifier returns the same events notifier '
    'that publishers use',
    (WidgetTester tester) async {
      late MovieSubscriptionEvents resolved;
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context, listen: false);
                resolved = resolveMovieSubscriptionNotifier(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(
        resolved,
        same(container.read(movieSubscriptionEventsProvider.notifier)),
      );
    },
  );

  test('refresh confirmation copy follows the caller locale', () {
    final en = AppLocalizationsEn();
    final zh = AppLocalizationsZh();

    // 英文界面不得出现中文：刷新确认弹窗曾经整段硬编码中文。
    final enCopy = <String>[
      MovieDetailRefreshConfirmationCopy.title(en),
      MovieDetailRefreshConfirmationCopy.hint(en),
      MovieDetailRefreshConfirmationCopy.cancelLabel(en),
      MovieDetailRefreshConfirmationCopy.confirmLabel(en),
      MovieDetailRefreshConfirmationCopy.descriptionFor(
        en,
        isActorsManuallyManaged: false,
      ),
      MovieDetailRefreshConfirmationCopy.descriptionFor(
        en,
        isActorsManuallyManaged: true,
      ),
    ];
    for (final copy in enCopy) {
      expect(copy, isNotEmpty);
      expect(_cjk.hasMatch(copy), isFalse);
    }

    final zhCopy = <String>[
      MovieDetailRefreshConfirmationCopy.title(zh),
      MovieDetailRefreshConfirmationCopy.hint(zh),
      MovieDetailRefreshConfirmationCopy.cancelLabel(zh),
      MovieDetailRefreshConfirmationCopy.confirmLabel(zh),
    ];
    for (final copy in zhCopy) {
      expect(_cjk.hasMatch(copy), isTrue);
    }

    // 演员表手动管理时要说明「不会覆盖」，用的是另一段说明。
    final manual = MovieDetailRefreshConfirmationCopy.descriptionFor(
      en,
      isActorsManuallyManaged: true,
    );
    final automatic = MovieDetailRefreshConfirmationCopy.descriptionFor(
      en,
      isActorsManuallyManaged: false,
    );
    expect(manual, isNot(automatic));
  });
}

Future<MovieDetailRemoteActionSpec> _runRemoteActionSpec({
  required MovieDetailActionType action,
  required String expectedPath,
  Map<String, dynamic>? expectedBody,
}) async {
  final sessionStore = SessionStore.inMemory();
  await sessionStore.saveBaseUrl('https://api.example.com');
  await sessionStore.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.parse('2026-03-08T10:00:00Z'),
  );
  final apiClient = ApiClient(sessionStore: sessionStore);
  final adapter = FakeHttpClientAdapter();
  apiClient.rawDio.httpClientAdapter = adapter;
  apiClient.rawRefreshDio.httpClientAdapter = adapter;
  final moviesApi = MoviesApi(apiClient: apiClient);
  final spec = movieDetailRemoteActionSpecFor(
    action: action,
    movieNumber: 'ABC-001',
    l10n: AppLocalizationsZh(),
  )!;
  final response = action == MovieDetailActionType.recomputeHeat
      ? <String, dynamic>{
          'task_run_id': 42,
          'task_key': 'movie_heat_update',
          'state': 'pending',
        }
      : <String, dynamic>{
          'javdb_id': 'movie-1',
          'movie_number': 'ABC-001',
          'title': 'Movie',
          'series_name': '',
          'maker_name': '',
          'director_name': '',
          'cover_image': null,
          'release_date': '2024-01-01',
          'duration_minutes': 120,
          'score': 4.5,
          'heat': 1,
          'watched_count': 1,
          'want_watch_count': 2,
          'comment_count': 3,
          'score_number': 4,
          'is_collection': false,
          'is_subscribed': false,
          'can_play': true,
          'summary': '',
          'thin_cover_image': null,
          'plot_images': const <Map<String, dynamic>>[],
          'actors': const <Map<String, dynamic>>[],
          'tags': const <Map<String, dynamic>>[],
          'media_items': const <Map<String, dynamic>>[],
          'playlists': const <Map<String, dynamic>>[],
        };
  adapter.enqueueJson(
    method: 'POST',
    path: expectedPath,
    statusCode: action == MovieDetailActionType.recomputeHeat ? 202 : 200,
    body: response,
  );

  await spec.request(moviesApi);
  expect(adapter.requests.single.path, expectedPath);
  if (expectedBody != null) {
    expect(adapter.requests.single.body, expectedBody);
  }
  apiClient.dispose();
  return spec;
}

/// applyReturnedMovieDetail 需要 [WidgetRef]，用最小 widget test 抓一个 ref。
/// 在 post-frame 里跑，避免 Consumer build 中修改 provider 触发的
/// 「build 中不得修改 provider」断言。
Future<MovieDetailApplyResult> _runApplyReturnedMovieDetail(
  WidgetTester tester, {
  required MovieDetailDto movie,
  required int? selectedMediaId,
  bool resetPreview = false,
  String movieNumber = 'ABC-001',
}) async {
  final completer = Completer<MovieDetailApplyResult>();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (completer.isCompleted) return;
              completer.complete(
                applyReturnedMovieDetail(
                  ref: ref,
                  movieNumber: movieNumber,
                  movie: movie,
                  selectedMediaId: selectedMediaId,
                  resetPreview: resetPreview,
                ),
              );
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return completer.future;
}

MovieDetailDto _movieDetail({
  String javdbId = 'movie-1',
  List<int> mediaIds = const <int>[10, 20],
  List<MoviePlaylistSummaryDto> playlists = const <MoviePlaylistSummaryDto>[],
  int? favoritePlaylistId,
}) {
  return MovieDetailDto(
    javdbId: javdbId,
    movieNumber: 'ABC-001',
    title: 'Movie',
    seriesName: '',
    makerName: '',
    directorName: '',
    coverImage: const MovieImageDto(id: 1, origin: '/covers/1.jpg'),
    releaseDate: DateTime.parse('2024-01-01'),
    durationMinutes: 120,
    score: 4.5,
    heat: 12,
    watchedCount: 1,
    wantWatchCount: 2,
    commentCount: 3,
    scoreNumber: 4,
    isCollection: false,
    isSubscribed: false,
    canPlay: true,
    summary: '',
    thinCoverImage: null,
    plotImages: const <MovieImageDto>[],
    actors: const <MovieActorDto>[],
    tags: const <MovieTagDto>[],
    mediaItems: mediaIds
        .map(
          (mediaId) => MovieMediaItemDto(
            mediaId: mediaId,
            libraryId: 1,
            providerKey: 'filesystem',
            playUrl: '/play/$mediaId',
            fileName: 'movie.mp4',
            resolution: '1080p',
            fileSizeBytes: 10,
            durationSeconds: 120,
            valid: true,
            progress: null,
            points: const <MovieMediaPointDto>[],
            videoInfo: null,
          ),
        )
        .toList(growable: false),
    playlists: playlists,
    favoritePlaylistId: favoritePlaylistId,
  );
}
