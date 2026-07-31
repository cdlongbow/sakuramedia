import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_play_url_dto.dart';
import 'package:sakuramedia/features/media/data/media_storage_descriptor.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_playback_options.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_playback_options_bar.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  const localStorage = MediaStorageDescriptor(
    libraryId: 1,
    libraryName: '本地库',
    backend: MediaLibraryBackend.local,
  );
  const cloudStorage = MediaStorageDescriptor(
    libraryId: 2,
    libraryName: '云盘库',
    backend: MediaLibraryBackend.cloud115,
  );
  const storageDescriptors = <int, MediaStorageDescriptor>{
    1: localStorage,
    2: cloudStorage,
  };

  MovieMediaItemDto media({
    required int mediaId,
    required int libraryId,
    String playUrl = '/media/1/stream?expires=1&signature=x',
  }) {
    return MovieMediaItemDto(
      mediaId: mediaId,
      libraryId: libraryId,
      playUrl: playUrl,
      storageMode: 'copy',
      resolution: '1920x1080',
      fileSizeBytes: 1024,
      durationSeconds: 3600,
      specialTags: '普通',
      valid: true,
      progress: null,
      points: const <MovieMediaPointDto>[],
      videoInfo: null,
    );
  }

  group('resolveMoviePlaybackSourceOptions', () {
    test('counts playable local and cloud115 media', () {
      final options = resolveMoviePlaybackSourceOptions(
        mediaItems: <MovieMediaItemDto>[
          media(mediaId: 1, libraryId: 1),
          media(mediaId: 2, libraryId: 1),
          media(mediaId: 3, libraryId: 2),
        ],
        storageDescriptors: storageDescriptors,
      );

      expect(options.localCount, 2);
      expect(options.cloud115Count, 1);
      expect(options.hasBothSources, isTrue);
      expect(options.defaultSource, MoviePlayUrlSource.local);
    });

    test('ignores media without playable url', () {
      final options = resolveMoviePlaybackSourceOptions(
        mediaItems: <MovieMediaItemDto>[
          media(mediaId: 1, libraryId: 1),
          media(mediaId: 2, libraryId: 1, playUrl: ''),
        ],
        storageDescriptors: storageDescriptors,
      );

      expect(options.localCount, 1);
      expect(options.hasBothSources, isFalse);
    });

    test('defaults to cloud115 when no local media', () {
      final options = resolveMoviePlaybackSourceOptions(
        mediaItems: <MovieMediaItemDto>[
          media(mediaId: 3, libraryId: 2),
        ],
        storageDescriptors: storageDescriptors,
      );

      expect(options.localCount, 0);
      expect(options.cloud115Count, 1);
      expect(options.defaultSource, MoviePlayUrlSource.cloud115);
    });

    test('returns null default when nothing playable', () {
      final options = resolveMoviePlaybackSourceOptions(
        mediaItems: <MovieMediaItemDto>[],
        storageDescriptors: storageDescriptors,
      );

      expect(options.defaultSource, isNull);
    });
  });

  group('resolveFirstPlayableMediaId', () {
    test('returns first playable media id of the source', () {
      final mediaItems = <MovieMediaItemDto>[
        media(mediaId: 1, libraryId: 1),
        media(mediaId: 2, libraryId: 2),
        media(mediaId: 3, libraryId: 1),
      ];

      expect(
        resolveFirstPlayableMediaId(
          mediaItems: mediaItems,
          storageDescriptors: storageDescriptors,
          source: MoviePlayUrlSource.local,
        ),
        1,
      );
      expect(
        resolveFirstPlayableMediaId(
          mediaItems: mediaItems,
          storageDescriptors: storageDescriptors,
          source: MoviePlayUrlSource.cloud115,
        ),
        2,
      );
    });

    test('returns null when source has no media', () {
      expect(
        resolveFirstPlayableMediaId(
          mediaItems: <MovieMediaItemDto>[
            media(mediaId: 1, libraryId: 1),
          ],
          storageDescriptors: storageDescriptors,
          source: MoviePlayUrlSource.cloud115,
        ),
        isNull,
      );
    });
  });

  group('MoviePlaybackOptionsBar', () {
    testWidgets('hides entirely when single source and no merge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          child: MoviePlaybackOptionsBar(
            sourceOptions: const MoviePlaybackSourceOptions(
              localCount: 1,
              cloud115Count: 0,
            ),
            selectedSource: MoviePlayUrlSource.local,
            onSourceChanged: (_) {},
            mergedAvailable: false,
            selectedMode: MoviePlayUrlMode.single,
            onModeChanged: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('movie-playback-options-bar')), findsNothing);
      expect(find.byKey(const Key('movie-playback-source-local')), findsNothing);
      expect(
        find.byKey(const Key('movie-playback-mode-merged')),
        findsNothing,
      );
    });

    testWidgets('shows source pills when both sources present', (
      WidgetTester tester,
    ) async {
      MoviePlayUrlSource? changed;
      await tester.pumpWidget(
        _testApp(
          child: MoviePlaybackOptionsBar(
            sourceOptions: const MoviePlaybackSourceOptions(
              localCount: 2,
              cloud115Count: 1,
            ),
            selectedSource: MoviePlayUrlSource.local,
            onSourceChanged: (source) => changed = source,
            mergedAvailable: false,
            selectedMode: MoviePlayUrlMode.single,
            onModeChanged: (_) {},
          ),
        ),
      );

      expect(find.text('播放源'), findsOneWidget);
      expect(find.text('本地存储'), findsOneWidget);
      expect(find.text('115 网盘'), findsOneWidget);
      expect(find.text('播放模式'), findsNothing);

      await tester.tap(find.byKey(const Key('movie-playback-source-cloud115')));
      expect(changed, MoviePlayUrlSource.cloud115);
    });

    testWidgets('shows merge mode row only when available', (
      WidgetTester tester,
    ) async {
      MoviePlayUrlMode? changed;
      await tester.pumpWidget(
        _testApp(
          child: MoviePlaybackOptionsBar(
            sourceOptions: const MoviePlaybackSourceOptions(
              localCount: 3,
              cloud115Count: 0,
            ),
            selectedSource: MoviePlayUrlSource.local,
            onSourceChanged: (_) {},
            mergedAvailable: true,
            selectedMode: MoviePlayUrlMode.single,
            onModeChanged: (mode) => changed = mode,
          ),
        ),
      );

      expect(find.text('播放源'), findsNothing);
      expect(find.text('播放模式'), findsOneWidget);
      expect(find.text('单个播放'), findsOneWidget);
      expect(find.text('合并播放'), findsOneWidget);

      await tester.tap(find.byKey(const Key('movie-playback-mode-merged')));
      expect(changed, MoviePlayUrlMode.merged);
    });
  });
}

Widget _testApp({required Widget child}) {
  final sessionStore = SessionStore.inMemory();
  return ChangeNotifierProvider<SessionStore>.value(
    value: sessionStore,
    child: MaterialApp(theme: sakuraThemeData, home: Scaffold(body: child)),
  );
}
