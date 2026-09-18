import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_detail_page_content.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_bottom_info_bar.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_section.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_ranking_list.dart';
import 'package:sakuramedia/theme.dart';

const _previewDirectory = '/tmp/sakuramedia-movie-detail-rankings-20260920';

void main() {
  setUpAll(_loadPreviewFonts);

  testWidgets('captures desktop movie detail rankings section', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureDetailPage(
        tester,
        size: const Size(1100, 760),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        padding: AppPageInsets.desktopStandard,
        mobile: false,
        outputPath:
            '$_previewDirectory/desktop-movie-detail-rankings-1100x760.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures mobile movie detail rankings section', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _captureDetailPage(
        tester,
        size: const Size(390, 844),
        platform: TargetPlatform.android,
        theme: sakuraMobileThemeData,
        padding: AppPageInsets.compactStandard,
        mobile: true,
        outputPath:
            '$_previewDirectory/mobile-movie-detail-rankings-390x844.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures narrow mobile movie detail rankings section', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _captureDetailPage(
        tester,
        size: const Size(360, 760),
        platform: TargetPlatform.android,
        theme: sakuraMobileThemeData,
        padding: AppPageInsets.compactStandard,
        mobile: true,
        outputPath:
            '$_previewDirectory/mobile-movie-detail-rankings-360x760.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures rankings section closeup with many placements', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureSectionCloseup(
        tester,
        rankings: _manyRankings(),
        outputPath: '$_previewDirectory/rankings-closeup-many-2x.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures rankings section closeup with one placement', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureSectionCloseup(
        tester,
        rankings: const <MovieRankingDto>[
          MovieRankingDto(
            sourceKey: 'javdb',
            sourceName: 'JavDB',
            boardKey: 'playback_all',
            boardName: '热播',
            period: 'daily',
            rank: 3,
          ),
        ],
        outputPath: '$_previewDirectory/rankings-closeup-single-2x.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Future<void> _captureDetailPage(
  WidgetTester tester, {
  required Size size,
  required TargetPlatform platform,
  required ThemeData theme,
  required EdgeInsets padding,
  required bool mobile,
  required String outputPath,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final movie = _movieDetail();
  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _previewTheme(theme, platform),
      home: Scaffold(
        body: Builder(
          builder: (context) => RepaintBoundary(
            key: boundaryKey,
            child: Padding(
              padding: padding,
              child: MovieDetailPageContent(
                movie: movie,
                selectedPreviewKey: 'preview',
                selectedPreviewUrl: null,
                isCollection: false,
                isSubscribed: true,
                isCollectionUpdating: false,
                isSubscriptionUpdating: false,
                selectedMediaId: movie.mediaItems.first.mediaId,
                statItems: buildMovieDetailStatItems(context, movie),
                similarMovies: const <MovieListItemDto>[],
                isSimilarMoviesLoading: false,
                bottomInfoBarVariant: mobile
                    ? MovieDetailBottomInfoBarVariant.mobileFullWidth
                    : MovieDetailBottomInfoBarVariant.desktopCard,
                onInspectorTap: _noop,
                onPlaylistTap: _noop,
                onCollectionToggle: _noop,
                onMediaSelect: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.byKey(const Key('movie-rankings-title')),
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
  await tester.pumpAndSettle();

  expect(
    find.byKey(const Key('movie-rankings-title')).hitTestable(),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
  await _capture(tester, boundaryKey, outputPath);
}

Future<void> _captureSectionCloseup(
  WidgetTester tester, {
  required List<MovieRankingDto> rankings,
  required String outputPath,
}) async {
  tester.view.physicalSize = const Size(720, 420);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _previewTheme(sakuraThemeData, TargetPlatform.macOS),
      home: Scaffold(
        body: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            color: AppColors.defaults().surfaceCard,
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topLeft,
              child: MovieDetailSection(
                title: '榜单',
                child: MovieRankingList(rankings: rankings),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  await _capture(tester, boundaryKey, outputPath, pixelRatio: 2);
}

MovieDetailDto _movieDetail() {
  return MovieDetailDto(
    id: 1,
    javdbId: 'SONE-118',
    movieNumber: 'SONE-118',
    title: '新人女优 独占デビュー 特别篇',
    seriesId: 7,
    seriesName: '新人女优系列',
    makerName: 'S1 NO.1 STYLE',
    directorName: '紋℃',
    coverImage: null,
    releaseDate: DateTime(2026, 8, 21),
    durationMinutes: 148,
    score: 4.62,
    heat: 1284,
    watchedCount: 328,
    wantWatchCount: 1024,
    commentCount: 96,
    scoreNumber: 214,
    isCollection: false,
    isSubscribed: true,
    canPlay: true,
    summary:
        '在夏日的海边小镇上，新人女优完成了她的出道作品。'
        '从清晨的散步到夜晚的烟火，镜头记录了全部真实反应。',
    thinCoverImage: null,
    plotImages: const <MovieImageDto>[],
    actors: const <MovieActorDto>[
      MovieActorDto(
        id: 1,
        javdbId: 'actor-1',
        name: '三上悠亚',
        aliasName: '三上悠亚',
        gender: MovieActorDto.femaleGender,
        isSubscribed: true,
        profileImage: null,
      ),
      MovieActorDto(
        id: 2,
        javdbId: 'actor-2',
        name: '导演助手',
        aliasName: '导演助手',
        gender: 0,
        isSubscribed: false,
        profileImage: null,
      ),
    ],
    tags: const <MovieTagDto>[
      MovieTagDto(tagId: 1, name: '单体作品'),
      MovieTagDto(tagId: 2, name: '高清'),
      MovieTagDto(tagId: 3, name: '剧情'),
      MovieTagDto(tagId: 4, name: '中出'),
    ],
    mediaItems: <MovieMediaItemDto>[
      MovieMediaItemDto(
        mediaId: 100,
        libraryId: 1,
        providerKey: 'filesystem',
        playUrl: '/media/SONE-118.mp4',
        fileName: 'SONE-118-4K.mp4',
        resolution: '3840x2160',
        fileSizeBytes: 12884901888,
        durationSeconds: 8880,
        valid: true,
        progress: MovieMediaProgressDto(
          lastPositionSeconds: 4378,
          lastWatchedAt: DateTime(2026, 9, 18, 22, 15),
        ),
        points: const <MovieMediaPointDto>[],
      ),
    ],
    playlists: const <MoviePlaylistSummaryDto>[
      MoviePlaylistSummaryDto(
        id: 1,
        name: '周末待看',
        kind: 'custom',
        isSystem: false,
      ),
    ],
    rankings: _manyRankings(),
  );
}

/// 取真实数据里常见的最坏情况：同榜单多周期 + TOP250 子榜/年份 + 第二个来源。
List<MovieRankingDto> _manyRankings() {
  return const <MovieRankingDto>[
    MovieRankingDto(
      sourceKey: 'javdb',
      sourceName: 'JavDB',
      boardKey: 'playback_all',
      boardName: '热播',
      period: 'daily',
      rank: 40,
    ),
    MovieRankingDto(
      sourceKey: 'javdb',
      sourceName: 'JavDB',
      boardKey: 'playback_high_score',
      boardName: '高评分',
      period: 'daily',
      rank: 29,
    ),
    MovieRankingDto(
      sourceKey: 'javdb',
      sourceName: 'JavDB',
      boardKey: 'uncensored',
      boardName: '无码',
      period: 'daily',
      rank: 21,
    ),
    MovieRankingDto(
      sourceKey: 'javdb',
      sourceName: 'JavDB',
      boardKey: 'uncensored',
      boardName: '无码',
      period: 'weekly',
      rank: 22,
    ),
    MovieRankingDto(
      sourceKey: 'javdb',
      sourceName: 'JavDB',
      boardKey: 'uncensored',
      boardName: '无码',
      period: 'monthly',
      rank: 26,
    ),
    MovieRankingDto(
      sourceKey: 'javdb',
      sourceName: 'JavDB',
      boardKey: 'top250',
      boardName: 'TOP250',
      period: '2023',
      rank: 13,
    ),
    MovieRankingDto(
      sourceKey: 'javdb',
      sourceName: 'JavDB',
      boardKey: 'top250',
      boardName: 'TOP250',
      period: 'fc2',
      rank: 1,
    ),
    MovieRankingDto(
      sourceKey: 'minnano',
      sourceName: '更多影片榜单',
      boardKey: 'minnano_av',
      boardName: 'Minnano AV 每日人气排行榜',
      period: 'daily',
      rank: 128,
    ),
  ];
}

ThemeData _previewTheme(ThemeData theme, TargetPlatform platform) {
  return theme.copyWith(
    platform: platform,
    textTheme: theme.textTheme.apply(fontFamily: 'PreviewCjk'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'PreviewCjk'),
  );
}

Future<void> _loadPreviewFonts() async {
  final cjkFont = FontLoader('PreviewCjk');
  final cjkBytes = await File(
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
  ).readAsBytes();
  cjkFont.addFont(Future<ByteData>.value(ByteData.sublistView(cjkBytes)));
  await cjkFont.load();

  final iconFont = FontLoader('MaterialIcons');
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    throw StateError('FLUTTER_ROOT is required to load MaterialIcons');
  }
  final iconBytes = await File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  iconFont.addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes)));
  await iconFont.load();
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String outputPath, {
  double pixelRatio = 1,
}) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
  expect(tester.takeException(), isNull);
}

void _noop() {}
