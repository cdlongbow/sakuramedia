import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/riverpod_page_cache.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/asset_summary_card.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/routes/app_router.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/logged_in_session_store.dart';
import '../../../../../support/test_api_bundle.dart';

const _previewDirectory = '/tmp/sakuramedia-overview-preview-20260920';

void main() {
  setUpAll(_loadPreviewFonts);

  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sessionStore = await buildLoggedInSessionStore();
    bundle = await createTestApiBundle(sessionStore);
    _enqueueOverviewData(bundle);
  });

  tearDown(() {
    bundle.dispose();
    sessionStore.dispose();
  });

  testWidgets('captures desktop overview (stacked)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(1100, 760),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        routePath: desktopOverviewPath,
        buildRouter: () => buildDesktopRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/desktop-overview-1100x760.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures desktop overview (two columns)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(1560, 1000),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        routePath: desktopOverviewPath,
        buildRouter: () => buildDesktopRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/desktop-overview-1560x1000.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures desktop latest movies page', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(1560, 1000),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        routePath: desktopLatestMoviesPath,
        buildRouter: () => buildDesktopRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/desktop-latest-movies-1560x1000.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures desktop overview (full page)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(1560, 2620),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        routePath: desktopOverviewPath,
        buildRouter: () => buildDesktopRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/desktop-overview-full-1560x2620.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures mobile overview my tab', (tester) async {
    // 播放列表封面是逐条后台拉取，预览里让它停在加载态，避免请求链留到测试结束。
    for (var index = 0; index < 2; index += 1) {
      bundle.adapter.enqueueResponder(
        method: 'GET',
        path: '/playlists',
        responder: (_, _) => Completer<ResponseBody>().future,
      );
    }
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(390, 844),
        platform: TargetPlatform.android,
        theme: sakuraMobileThemeData,
        routePath: mobileOverviewPath,
        buildRouter: () => buildMobileRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/mobile-overview-my-tab-390x844.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures mobile latest movies page', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(390, 844),
        platform: TargetPlatform.android,
        theme: sakuraMobileThemeData,
        routePath: mobileLatestMoviesPath,
        buildRouter: () => buildMobileRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/mobile-latest-movies-390x844.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures mobile system overview (full page)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(390, 1560),
        platform: TargetPlatform.android,
        theme: sakuraMobileThemeData,
        routePath: mobileSystemOverviewPath,
        buildRouter: () => buildMobileRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/mobile-system-overview-390x1560.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures mobile system overview (narrow)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(360, 1500),
        platform: TargetPlatform.android,
        theme: sakuraMobileThemeData,
        routePath: mobileSystemOverviewPath,
        buildRouter: () => buildMobileRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/mobile-system-overview-360x1500.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures asset summary card closeup', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final boundaryKey = GlobalKey();
      // DPR=2：760×260 逻辑尺寸输出 1520×520，方便放大检查图标与文字对齐。
      tester.view.physicalSize = const Size(1520, 520);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _previewTheme(sakuraDesktopThemeData, TargetPlatform.macOS),
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: AssetSummaryCard(
              status: _statusDto(),
              insights: StatusInsightsDto(
                collections: CollectionsStatsDto(
                  playlists: const CollectionSummaryDto(count: 21, itemCount: 42),
                  videoCollections: const CollectionSummaryDto(count: 12),
                  clipCollections: const CollectionSummaryDto(count: 1),
                  momentCollections: const CollectionSummaryDto(count: 1),
                ),
              ),
              pendingIndexCount: 12,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePreview(
        tester,
        boundaryKey,
        '$_previewDirectory/asset-summary-card-closeup-2x.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures desktop overview (loading)', (tester) async {
    _stallOverviewRequests(bundle);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(1100, 760),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        routePath: desktopOverviewPath,
        buildRouter: () => buildDesktopRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/desktop-overview-loading-1100x760.png',
        settle: false,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures desktop overview (empty)', (tester) async {
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/playlists',
      body: <dynamic>[],
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/status',
      body: <String, dynamic>{
        'backend_version': '',
        'actors': <String, dynamic>{'female_total': 0, 'female_subscribed': 0},
        'movies': <String, dynamic>{
          'total': 0,
          'subscribed': 0,
          'playable': 0,
        },
        'media_files': <String, dynamic>{'total': 0, 'total_size_bytes': 0},
        'media_libraries': <String, dynamic>{'total': 0},
        'thumbnails': <String, dynamic>{
          'pending_media': 0,
          'retry_wait_media': 0,
          'terminal_failed_media': 0,
          'total': 0,
        },
      },
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/status/image-search',
      body: <String, dynamic>{},
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/status/insights',
      body: <String, dynamic>{},
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/status/watch-trend',
      body: <String, dynamic>{
        'range': '30d',
        'granularity': 'day',
        'watched_movie_count': 0,
        'buckets': <dynamic>[],
      },
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/movies/latest',
      body: <String, dynamic>{
        'items': <dynamic>[],
        'page': 1,
        'page_size': 24,
        'total': 0,
      },
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(1100, 760),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        routePath: desktopOverviewPath,
        buildRouter: () => buildDesktopRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/desktop-overview-empty-1100x760.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('captures desktop overview (error)', (tester) async {
    for (final path in <String>[
      '/status',
      '/status/insights',
      '/status/watch-trend',
      '/status/image-search',
    ]) {
      bundle.adapter.setFallbackJson(
        method: 'GET',
        path: path,
        statusCode: 500,
        body: <String, dynamic>{
          'error': <String, dynamic>{'code': 'internal_error', 'message': 'boom'},
        },
      );
    }
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _captureScreen(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        size: const Size(1100, 760),
        platform: TargetPlatform.macOS,
        theme: sakuraDesktopThemeData,
        routePath: desktopOverviewPath,
        buildRouter: () => buildDesktopRouter(sessionStore: sessionStore),
        outputPath: '$_previewDirectory/desktop-overview-error-1100x760.png',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// 让概览四条加载腿停在加载态，用于截取骨架屏。
void _stallOverviewRequests(TestApiBundle bundle) {
  for (final path in <String>[
    '/status',
    '/status/insights',
    '/status/watch-trend',
    '/status/image-search',
    '/movies/latest',
    '/playlists',
  ]) {
    for (var index = 0; index < 4; index += 1) {
      // 侧栏版本卡片与概览会各发一次请求，多排几个避免退到有数据的兜底。
      bundle.adapter.enqueueResponder(
        method: 'GET',
        path: path,
        responder: (_, _) => Completer<ResponseBody>().future,
      );
    }
  }
}

Future<void> _captureScreen(
  WidgetTester tester, {
  required TestApiBundle bundle,
  required SessionStore sessionStore,
  required Size size,
  required TargetPlatform platform,
  required ThemeData theme,
  required String routePath,
  required GoRouter Function() buildRouter,
  required String outputPath,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final boundaryKey = GlobalKey();
  final router = buildRouter()..go(routePath);
  await tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(
        pageStateCache: RiverpodPageCache()..bindSessionStore(sessionStore),
      ),
      child: OKToast(
        child: RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: _previewTheme(theme, platform),
            routerConfig: router,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    // 概览页有多条异步链（状态/趋势/封面等），多轮 pump 让零延迟定时器链跑完。
    await tester.pumpAndSettle();
    for (var round = 0; round < 8; round += 1) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(tester.takeException(), isNull);
  await capturePreview(tester, boundaryKey, outputPath);
}

void _enqueueOverviewData(TestApiBundle bundle) {
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/system/plugins',
    body: <dynamic>[],
  );
  for (final repo in <String>['sakuramedia', 'sakuramediabe']) {
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: 'https://api.github.com/repos/tinypinglite/$repo/releases/latest',
      body: <String, dynamic>{'tag_name': 'v9.9.9'},
    );
  }
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/status',
    body: <String, dynamic>{
      'backend_version': '',
      'actors': <String, dynamic>{'female_total': 128, 'female_subscribed': 34},
      'movies': <String, dynamic>{
        'total': 1286,
        'subscribed': 87,
        'playable': 1104,
      },
      'media_files': <String, dynamic>{
        'total': 2410,
        'total_size_bytes': 9876543210987,
      },
      'media_libraries': <String, dynamic>{'total': 3},
      'thumbnails': <String, dynamic>{
        'pending_media': 12,
        'retry_wait_media': 3,
        'terminal_failed_media': 4,
        'total': 2318,
      },
    },
  );
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/status/image-search',
    body: <String, dynamic>{
      'enabled': true,
      'healthy': true,
      'checked_at': '2026-09-20T12:00:00',
      'embedding_service': <String, dynamic>{
        'healthy': true,
        'endpoint': 'http://joytag:8080',
        'space_id': 'siglip2-base',
        'dimension': 768,
        'modalities': <String>['image', 'text'],
        'error': null,
      },
      'image_search_vector_store': <String, dynamic>{
        'healthy': true,
        'url': 'http://qdrant:6333',
        'collection_name': 'media_thumbnail_vectors',
        'exists': true,
        'points_count': 2318,
        'vector_size': 768,
        'vector_dtype': 'float16',
        'collection_status': 'green',
        'error': null,
      },
      'indexing': <String, dynamic>{
        'pending_thumbnails': 12,
        'failed_thumbnails': 4,
      },
      'index_space': <String, dynamic>{
        'state': 'ready',
        'indexed_space_id': 'siglip2-base',
        'current_space_id': 'siglip2-base',
        'is_rebuilding': false,
      },
    },
  );
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/playlists',
    body: <dynamic>[
      <String, dynamic>{
        'id': 9,
        'name': '最近播放',
        'kind': 'recently_played',
        'description': '系统自动维护的最近播放影片列表',
        'is_system': true,
        'is_mutable': false,
        'is_deletable': false,
        'movie_count': 12,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-09-20T00:00:00Z',
      },
    ],
  );
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/playlists/9/movies',
    body: <String, dynamic>{
      'items': <dynamic>[
        _movieJson('ABW-045', '夏日海滩写真集', subscribed: true),
        _movieJson('SSIS-001', '新人女优 独占デビュー', subscribed: true),
        _movieJson('IPX-580', '温泉旅馆的相遇', subscribed: true),
        _movieJson('MIDV-128', '午后教室的特别补习', subscribed: false),
        _movieJson('MIDE-672', '邻家的人妻', subscribed: false),
        _movieJson('STARS-402', '初恋的回忆', subscribed: false),
        _movieJson('SSNI-888', '深夜电台的告白', subscribed: false),
        _movieJson('PRED-309', '办公室的秘密', subscribed: false),
        _movieJson('FSDSS-512', '雨天的图书馆', subscribed: false),
        _movieJson('JUQ-215', '第一次的出差', subscribed: false),
        _movieJson('SONE-118', '夏夜的烟火', subscribed: false),
        _movieJson('DASS-330', '搬家那天', subscribed: false),
      ],
      'page': 1,
      'page_size': 24,
      'total': 12,
    },
  );
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/status/insights',
    body: <String, dynamic>{
      'media_libraries': <dynamic>[
        <String, dynamic>{
          'library_id': 1,
          'name': '主媒体库',
          'provider_key': 'local',
          'file_count': 1420,
          'total_size_bytes': 6400000000000,
        },
        <String, dynamic>{
          'library_id': 2,
          'name': '备份库',
          'provider_key': 'cloud115',
          'file_count': 700,
          'total_size_bytes': 2300000000000,
        },
        <String, dynamic>{
          'library_id': 3,
          'name': '测试库',
          'provider_key': 'local',
          'file_count': 290,
          'total_size_bytes': 1176543210987,
        },
      ],
      'collections': <String, dynamic>{
        'playlists': <String, dynamic>{'count': 5, 'item_count': 42},
        'video_collections': <String, dynamic>{'count': 2, 'item_count': 8},
        'clip_collections': <String, dynamic>{'count': 8, 'item_count': 31},
        'moment_collections': <String, dynamic>{'count': 1, 'item_count': 3},
      },
    },
  );
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/status/watch-trend',
    body: _watchTrendJson(),
  );
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/movies/latest',
    body: <String, dynamic>{
      'items': _latestMovieJsonList(),
      'page': 1,
      'page_size': 24,
      'total': 18,
    },
  );
}

StatusDto _statusDto() {
  return const StatusDto(
    backendVersion: '',
    actors: ActorStatsDto(femaleTotal: 128, femaleSubscribed: 34),
    movies: MovieStatsDto(total: 1286, subscribed: 87, playable: 1104),
    mediaFiles: MediaFileStatsDto(
      total: 2410,
      totalSizeBytes: 9876543210987,
    ),
    mediaLibraries: MediaLibraryStatsDto(total: 3),
    thumbnails: ThumbnailStatsDto(
      pendingMedia: 12,
      retryWaitMedia: 3,
      terminalFailedMedia: 4,
      total: 2318,
    ),
  );
}

String _formatDay(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// 30 天窗口的观看趋势：总量与 `watched_movie_count` 保持一致（每部片只算一次）。
Map<String, dynamic> _watchTrendJson() {
  const counts = <int>[
    0, 1, 0, 2, 1, 0, 0, 1, 3, 2,
    0, 1, 2, 4, 1, 0, 2, 3, 1, 0,
    1, 2, 5, 3, 2, 1, 0, 2, 1, 2,
  ];
  final start = DateTime(2026, 8, 22);
  final buckets = <Map<String, dynamic>>[
    for (var index = 0; index < counts.length; index += 1)
      <String, dynamic>{
        'period': _formatDay(start.add(Duration(days: index))),
        'count': counts[index],
      },
  ];
  return <String, dynamic>{
    'range': '30d',
    'granularity': 'day',
    'watched_movie_count': counts.fold<int>(0, (sum, value) => sum + value),
    'buckets': buckets,
  };
}

List<Map<String, dynamic>> _latestMovieJsonList() {
  const titles = <String>[
    '新人女优 独占デビュー',
    '午后教室的特别补习',
    '夏日海滩写真集',
    '深夜电台的告白',
    '邻家的人妻',
    '温泉旅馆的相遇',
    '办公室的秘密',
    '初恋的回忆',
    '雨天的图书馆',
    '第一次的出差',
    '夏夜的烟火',
    '搬家那天',
    '樱花飞舞的春天',
    '咖啡店常客',
    '深夜食堂',
    '海边的小屋',
    '图书馆的午后',
    '冬日的暖阳',
  ];
  const numbers = <String>[
    'SSIS-001', 'MIDV-128', 'ABW-045', 'SSNI-888', 'MIDE-672', 'IPX-580',
    'PRED-309', 'STARS-402', 'FSDSS-512', 'JUQ-215', 'SONE-118', 'DASS-330',
    'SSIS-002', 'MIDV-129', 'ABW-046', 'SSNI-889', 'MIDE-673', 'IPX-581',
  ];
  return <Map<String, dynamic>>[
    for (var index = 0; index < titles.length; index += 1)
      _movieJson(numbers[index], titles[index], subscribed: index % 3 == 0),
  ];
}

Map<String, dynamic> _movieJson(
  String number,
  String title, {
  required bool subscribed,
}) {
  return <String, dynamic>{
    'id': number.hashCode,
    'javdb_id': number,
    'movie_number': number,
    'title': title,
    'series_id': null,
    'series_name': '',
    'cover_image': null,
    'thin_cover_image': null,
    'release_date': '2026-08-1${number.hashCode % 9}',
    'duration_minutes': 120,
    'heat': 100,
    'is_subscribed': subscribed,
    'can_play': true,
  };
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

Future<void> capturePreview(
  WidgetTester tester,
  GlobalKey key,
  String outputPath,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
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
}
