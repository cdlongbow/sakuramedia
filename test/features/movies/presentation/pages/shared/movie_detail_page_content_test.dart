import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_detail_page_content.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_hero_card.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_inspector_panel.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_tag_wrap.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_plot_gallery.dart';

void main() {
  testWidgets('personal info uses latest watch and opens playlist editor', (
    tester,
  ) async {
    var edits = 0;
    final media = _movieDetail().mediaItems.first;
    final movie = _movieDetail(
      mediaItems: [
        media.copyWith(
          progress: MovieMediaProgressDto(
            lastPositionSeconds: 3600,
            lastWatchedAt: DateTime(2026, 1, 1),
          ),
        ),
        media.copyWith(
          mediaId: 101,
          progress: MovieMediaProgressDto(
            lastPositionSeconds: 1938,
            lastWatchedAt: DateTime(2026, 2, 1),
          ),
        ),
      ],
      playlists: [
        for (var id = 1; id <= 3; id++)
          MoviePlaylistSummaryDto(
            id: id,
            name: '片单$id',
            kind: 'custom',
            isSystem: false,
          ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: movie,
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const [],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: () => edits++,
            onMediaSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 标题行：番号打头 + 同行标题。
    expect(find.text('ABC-001 Sample Movie'), findsOneWidget);
    expect(find.text('上次看到 32:18'), findsOneWidget);
    expect(find.text('片单1'), findsOneWidget);
    expect(find.text('共 3 个'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('movie-detail-playlist-trigger')));
    await tester.tap(find.byKey(const Key('movie-detail-playlist-trigger')));
    expect(edits, 1);
    await tester.ensureVisible(find.text('片单1'));
    await tester.tap(find.text('片单1'));
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });

  for (final mobile in [true, false]) {
    for (final showTags in [true, false]) {
      for (final showActors in [true, false]) {
        testWidgets(
          'detail hides empty sections (mobile: $mobile, tags: $showTags, actors: $showActors)',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = mobile
                ? const Size(360, 760)
                : const Size(1100, 760);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            var actorTaps = 0;
            var tagTaps = 0;
            await tester.pumpWidget(
              MaterialApp(
                theme: mobile ? sakuraMobileThemeData : sakuraThemeData,
                home: Scaffold(
                  body: MovieDetailPageContent(
                    movie: _movieDetail(
                      actors: showActors ? null : const [],
                      tags: showTags ? null : const [],
                    ),
                    surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
                    selectedPreviewKey: 'movie-preview',
                    selectedPreviewUrl: null,
                    isSubscribed: false,
                    isSubscriptionUpdating: false,
                    selectedMediaId: 100,
                    similarMovies: const [],
                    isSimilarMoviesLoading: false,
                    onInspectorPaneTap: _ignorePane,
                    onPlaylistTap: _noop,
                    onMediaSelect: (_) {},
                    onActorTap: (_) => actorTaps++,
                    onTagTap: (_) => tagTaps++,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('标签'), showTags ? findsOneWidget : findsNothing);
            expect(find.text('演员'), showActors ? findsOneWidget : findsNothing);
            expect(find.text('榜单'), findsNothing);
            expect(find.text('暂无观看记录'), findsNothing);
            expect(find.textContaining('上次看到'), findsNothing);
            expect(find.byType(MoviePlotGallery), findsNothing);
            if (showTags) {
              await tester.scrollUntilVisible(
                find.text('剧情'),
                200,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.tap(find.text('剧情'));
              expect(tagTaps, 1);
            }
            if (showActors) {
              await tester.scrollUntilVisible(
                find.text('演员一'),
                200,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.tap(find.text('演员一'));
              expect(actorTaps, 1);
            }
            await tester.scrollUntilVisible(
              find.text('媒体源'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('媒体源').hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('plugin movie displays its source and pending JavDB status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: _movieDetail(javdbId: null, metadataSourceName: '示例来源'),
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('元数据 · 示例来源 · 待 JavDB 收录'), findsOneWidget);
  });

  for (final mobile in [true, false]) {
    testWidgets(
      'detail shows ranking placements (mobile: $mobile)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = mobile
            ? const Size(360, 760)
            : const Size(1100, 760);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            theme: mobile ? sakuraMobileThemeData : sakuraThemeData,
            home: Scaffold(
              body: MovieDetailPageContent(
                movie: _movieDetail(
                  rankings: const <MovieRankingDto>[
                    MovieRankingDto(
                      sourceKey: 'javdb',
                      sourceName: 'JavDB',
                      boardKey: 'playback_all',
                      boardName: '热播',
                      period: 'daily',
                      rank: 3,
                    ),
                    MovieRankingDto(
                      sourceKey: 'javdb',
                      sourceName: 'JavDB',
                      boardKey: 'top250',
                      boardName: 'TOP250',
                      period: '2026',
                      rank: 28,
                    ),
                  ],
                ),
                surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
                selectedPreviewKey: 'movie-preview',
                selectedPreviewUrl: null,
                isSubscribed: false,
                isSubscriptionUpdating: false,
                selectedMediaId: 100,
                similarMovies: const <MovieListItemDto>[],
                isSimilarMoviesLoading: false,
                onInspectorPaneTap: _ignorePane,
                onPlaylistTap: _noop,
                onMediaSelect: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('榜单'), findsOneWidget);
        expect(find.text('热播 · 日榜'), findsOneWidget);
        expect(find.text('TOP250 · 2026年'), findsOneWidget);
        expect(find.text('#3'), findsOneWidget);
        expect(find.text('#28'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('movie DTOs accept plugin movies without a JavDB ID', () {
    final json = <String, dynamic>{
      'id': 12,
      'javdb_id': null,
      'movie_number': 'TEST-001',
      'title': 'Plugin title',
      'metadata_source': <String, dynamic>{
        'plugin_id': 'example',
        'display_name': '示例来源',
      },
    };
    final detail = MovieDetailDto.fromJson(json);
    final item = MovieListItemDto.fromJson(json);
    expect(detail.javdbId, isNull);
    expect(item.javdbId, isNull);
    expect(detail.metadataSourceName, '示例来源');
    expect(detail.score, 0);
    expect(detail.watchedCount, 0);
  });

  for (final seriesName in [
    'Attackers',
    '这是一个用于验证影片详情页面在窄屏下能够完整换行且不会溢出的超长系列名称',
  ]) {
    testWidgets(
      'movie detail wraps clickable series on narrow screens: $seriesName',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var tapCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: sakuraMobileThemeData,
            home: Scaffold(
              body: MovieDetailPageContent(
                movie: _movieDetail(seriesId: 7, seriesName: seriesName),
                surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
                selectedPreviewKey: 'movie-preview',
                selectedPreviewUrl: null,
                isSubscribed: false,
                isSubscriptionUpdating: false,
                selectedMediaId: 100,
                similarMovies: const <MovieListItemDto>[],
                isSimilarMoviesLoading: false,
                onInspectorPaneTap: _ignorePane,
                onPlaylistTap: _noop,
                onMediaSelect: (_) {},
                onSeriesTap: () => tapCount += 1,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final seriesLink = find.byKey(const Key('movie-detail-series-link'));
        final seriesText = find.text('系列 · $seriesName');
        await tester.ensureVisible(seriesLink);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(seriesText).right,
          lessThanOrEqualTo(tester.getRect(seriesLink).right),
        );
        if (seriesName != 'Attackers') {
          expect(tester.getSize(seriesText).height, greaterThan(30));
        }
        await tester.tap(seriesLink);
        await tester.pump();

        expect(tapCount, 1);
        expect(
          find.descendant(
            of: find.byKey(const Key('movie-detail-series-link')),
            matching: find.byIcon(Icons.chevron_right_rounded),
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('movie detail page content keeps series text plain without id', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: _movieDetail(),
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
            onSeriesTap: _noop,
          ),
        ),
      ),
    );

    expect(find.text('系列 · Attackers'), findsOneWidget);
    expect(find.byKey(const Key('movie-detail-series-link')), findsNothing);
  });

  testWidgets(
    'movie detail page content keeps grouped meta spacing in mobile theme',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      // 正文区块按需构建：撑高视口让简介 / 标签 / 演员同屏，位置比较才有意义。
      tester.view.physicalSize = const Size(400, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraMobileThemeData,
          home: Scaffold(
          body: MovieDetailPageContent(
            movie: _movieDetail(summary: '这是一段简介全文'),
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
              selectedPreviewKey: 'movie-preview',
              selectedPreviewUrl: null,
              isSubscribed: false,
              isSubscriptionUpdating: false,
              selectedMediaId: 100,
              similarMovies: const <MovieListItemDto>[],
              isSimilarMoviesLoading: false,
              onInspectorPaneTap: _ignorePane,
              onPlaylistTap: _noop,
              onMediaSelect: (_) {},
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('演员'));
      await tester.pumpAndSettle();

      final sectionGap = AppComponentTokens.mobile().movieDetailSectionGap;
      // 厂商/导演行已下线（进信息块 meta 行），行内只剩系列；简介全文保留在下方。
      expect(find.text('系列 · Attackers'), findsOneWidget);
      final inlineMeta = find.byKey(
        const Key('movie-detail-inline-meta-group'),
      );
      expect(
        find.descendant(of: inlineMeta, matching: find.text('厂商 · S1 NO.1 STYLE')),
        findsNothing,
      );
      expect(
        find.descendant(of: inlineMeta, matching: find.text('导演 · 紋℃')),
        findsNothing,
      );
      expect(find.byKey(const Key('movie-detail-summary')), findsOneWidget);
      expect(find.text('这是一段简介全文'), findsOneWidget);
      final metaGroupBottom = tester
          .getBottomLeft(
            find.byKey(const Key('movie-detail-inline-meta-group')),
          )
          .dy;
      final tagTop = tester.getTopLeft(find.text('标签')).dy;
      final tagWrapBottom = tester.getBottomLeft(find.byType(MovieTagWrap)).dy;
      final actorTop = tester.getTopLeft(find.text('演员')).dy;

      expect(tagTop - metaGroupBottom, sectionGap);
      expect(actorTop - tagWrapBottom, sectionGap);
      expect(find.text('媒体源'), findsOneWidget);
      expect(find.byKey(const Key('movie-subtitles-title')), findsNothing);
      expect(find.byKey(const Key('movie-similar-movies-title')), findsNothing);
    },
  );

  testWidgets('movie detail forwards hero fit to the hero card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: _movieDetail(),
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            heroImageFit: BoxFit.cover,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
          ),
        ),
      ),
    );

    final hero = tester.widget<MovieDetailHeroCard>(
      find.byType(MovieDetailHeroCard),
    );
    expect(hero.heroFit, BoxFit.cover);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movie detail places merge playback below the hero photo', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: _movieDetail(),
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
            onPlayTap: _noop,
            mergePlaybackLabel: '合并播放 · 2 段',
            onMergePlaybackTap: () => tapCount += 1,
          ),
        ),
      ),
    );

    final action = find.byKey(const Key('movie-detail-merge-playback-button'));
    await tester.ensureVisible(action);

    final heroBottom = tester
        .getBottomLeft(find.byType(MovieDetailHeroCard))
        .dy;
    final actionRect = tester.getRect(action);
    final playRect = tester.getRect(
      find.byKey(const Key('movie-detail-hero-play-button')),
    );

    // 分体键在照片下方的信息块里：与播放键同一行、位于右侧，整个在 Hero 之下。
    expect(actionRect.top, greaterThanOrEqualTo(heroBottom));
    expect(actionRect.top, closeTo(playRect.top, 1.0));
    expect(actionRect.left, greaterThan(playRect.left));
    expect(find.byTooltip('合并播放 · 2 段'), findsOneWidget);

    await tester.tap(action);
    await tester.pump();

    expect(tapCount, 1);
  });

  // 信息行展示语义的固化（有意精简，勿当回归改回）：
  // - 零值项整段隐藏（旧 NumberBar 会显示「想看人数 0」）；
  // - 评分保留一位小数（旧实现两位去尾零，4.57 会显示 4.57）；
  // - 不再展示「评分人数」（scoreNumber 无 UI 消费方）。
  testWidgets('meta row hides zero values and keeps one-decimal score', (
    tester,
  ) async {
    final movie = _movieDetail(
      score: 4.57,
      heat: 0,
      watchedCount: 0,
      wantWatchCount: 0,
      commentCount: 0,
      scoreNumber: 88,
      durationMinutes: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: movie,
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final metaRow = find.byKey(const Key('movie-detail-hero-overlay-meta'));
    expect(metaRow, findsOneWidget);
    expect(
      find.descendant(of: metaRow, matching: find.text('4.6')),
      findsOneWidget,
      reason: '评分一位小数',
    );
    expect(
      find.descendant(of: metaRow, matching: find.text('4.57')),
      findsNothing,
    );
    expect(find.textContaining('想看 · 0'), findsNothing);
    expect(find.textContaining('看过 · 0'), findsNothing);
    expect(find.textContaining('评分人数'), findsNothing);
    expect(find.textContaining('分钟'), findsNothing, reason: '零值时长隐藏');
    expect(find.text('88'), findsNothing, reason: 'scoreNumber 不再单独展示');
    expect(tester.takeException(), isNull);
  });

  testWidgets('meta row hides zero score and keeps positive counts', (
    tester,
  ) async {
    final movie = _movieDetail(score: 0, wantWatchCount: 23);
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: movie,
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0.0'), findsNothing, reason: '零评分隐藏');
    expect(find.textContaining('想看 · 23'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('detail action row opens the matching inspector dialog', (
    WidgetTester tester,
  ) async {
    final openedTabs = <MovieDetailInspectorPane>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: _movieDetail(),
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: openedTabs.add,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-detail-hero-review-icon')),
      findsOneWidget,
    );
    // 固定底栏已下线。
    expect(find.byKey(const Key('movie-detail-fixed-info-bar')), findsNothing);

    for (final key in const <String>[
      'movie-detail-hero-review-icon',
      'movie-detail-hero-magnet-search-icon',
      'movie-detail-hero-thumbnail-icon',
    ]) {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
    }
    await tester.pump();

    expect(openedTabs, <MovieDetailInspectorPane>[
      MovieDetailInspectorPane.review,
      MovieDetailInspectorPane.magnetSearch,
      MovieDetailInspectorPane.thumbnail,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail meta line carries the release date', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MovieDetailPageContent(
            movie: _movieDetail(releaseDate: DateTime(2024, 1, 2)),
            surfaceColor: sakuraMobileThemeData.appColors.surfaceCard,
            selectedPreviewKey: 'movie-preview',
            selectedPreviewUrl: null,
            isSubscribed: false,
            isSubscriptionUpdating: false,
            selectedMediaId: 100,
            similarMovies: const <MovieListItemDto>[],
            isSimilarMoviesLoading: false,
            onInspectorPaneTap: _ignorePane,
            onPlaylistTap: _noop,
            onMediaSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('上映 · 2024/01/02'), findsOneWidget);
    expect(find.text('120 分钟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

MovieDetailDto _movieDetail({
  int? seriesId,
  String seriesName = 'Attackers',
  String? javdbId = 'javdb-1',
  String? metadataSourceName,
  List<MovieMediaItemDto>? mediaItems,
  List<MoviePlaylistSummaryDto> playlists = const [],
  List<MovieActorDto>? actors,
  List<MovieTagDto>? tags,
  List<MovieRankingDto> rankings = const [],
  String summary = '',
  double score = 4.5,
  int heat = 12,
  int watchedCount = 12,
  int wantWatchCount = 23,
  int commentCount = 45,
  int scoreNumber = 45,
  int durationMinutes = 120,
  DateTime? releaseDate,
}) {
  return MovieDetailDto(
    javdbId: javdbId,
    metadataSourceName: metadataSourceName,
    movieNumber: 'ABC-001',
    title: 'Sample Movie',
    seriesId: seriesId,
    seriesName: seriesName,
    makerName: 'S1 NO.1 STYLE',
    directorName: '紋℃',
    coverImage: null,
    releaseDate: releaseDate,
    durationMinutes: durationMinutes,
    score: score,
    heat: heat,
    watchedCount: watchedCount,
    wantWatchCount: wantWatchCount,
    commentCount: commentCount,
    scoreNumber: scoreNumber,
    isCollection: false,
    isSubscribed: false,
    canPlay: false,
    summary: summary,
    thinCoverImage: null,
    plotImages: const <MovieImageDto>[],
    actors: actors ?? const <MovieActorDto>[
      MovieActorDto(
        id: 1,
        javdbId: 'actor-1',
        name: '演员一',
        aliasName: '演员一',
        gender: MovieActorDto.femaleGender,
        isSubscribed: false,
        profileImage: null,
      ),
      MovieActorDto(
        id: 2,
        javdbId: 'actor-2',
        name: '演员二',
        aliasName: '演员二',
        gender: 0,
        isSubscribed: false,
        profileImage: null,
      ),
    ],
    tags: tags ?? const <MovieTagDto>[
      MovieTagDto(tagId: 1, name: '单体作品'),
      MovieTagDto(tagId: 2, name: '剧情'),
    ],
    mediaItems:
        mediaItems ??
        const <MovieMediaItemDto>[
          MovieMediaItemDto(
            mediaId: 100,
            libraryId: 1,
            providerKey: 'filesystem',
            playUrl: '',
            fileName: 'ABC-001.mp4',
            resolution: '1920x1080',
            fileSizeBytes: 1073741824,
            durationSeconds: 7200,
            valid: true,
            progress: null,
            points: <MovieMediaPointDto>[],
          ),
        ],
    playlists: playlists,
    rankings: rankings,
  );
}

void _noop() {}

void _ignorePane(MovieDetailInspectorPane _) {}
