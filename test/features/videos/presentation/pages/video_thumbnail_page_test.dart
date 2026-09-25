import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/features/media/data/media_api.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/videos/data/api/videos_api.dart';
import 'package:sakuramedia/features/videos/data/dto/video_item_list_item_dto.dart';
import 'package:sakuramedia/features/videos/presentation/pages/desktop/video_actions_dialog.dart';
import 'package:sakuramedia/features/videos/presentation/pages/desktop/video_thumbnail_page.dart';
import 'package:sakuramedia/features/videos/presentation/pages/mobile/video_actions_sheet.dart';
import 'package:sakuramedia/features/videos/presentation/pages/mobile/video_thumbnail_page.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/app_image_action_menu.dart';
import 'package:sakuramedia/widgets/domain/media/media_thumbnail_action_support.dart';
import 'package:sakuramedia/widgets/shell/mobile/app_mobile_subpage_shell.dart';

import '../../../../support/fake_http_client_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final mobile in <bool>[false, true]) {
    testWidgets('${mobile ? '移动端' : '桌面端'} PornBox 缩略图页加载唯一媒体并显示共享工具栏', (
      tester,
    ) async {
      await _pumpVideoThumbnailPage(tester, mobile: mobile);

      expect(find.byKey(const Key('video-thumbnail-page')), findsOneWidget);
      expect(find.byKey(const Key('video-thumbnail-title')), findsOneWidget);
      expect(find.byKey(const Key('video-thumbnail-toolbar')), findsOneWidget);
      expect(
        find.byKey(const Key('video-thumbnail-thumbnail-grid')),
        findsOneWidget,
      );
      if (mobile) {
        // 窄屏收成两个紧凑入口，不再铺开 chips。
        expect(
          find.byKey(const Key('video-thumbnail-interval-trigger')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('video-thumbnail-columns-trigger')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('video-thumbnail-interval-10')),
          findsNothing,
        );
      } else {
        expect(
          find.byKey(const Key('video-thumbnail-interval-10')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('video-thumbnail-interval-trigger')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('移动端缩略图工具条用底部抽屉设置时间间隔与列数', (tester) async {
    await _pumpVideoThumbnailPage(tester, mobile: true);

    expect(find.text('10秒'), findsOneWidget);
    expect(find.byKey(const Key('video-thumbnail-thumb-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('video-thumbnail-interval-trigger')));
    await tester.pumpAndSettle();
    expect(find.text('缩略图时间间隔'), findsOneWidget);
    expect(find.text('20 秒'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('video-thumbnail-interval-option-20')),
    );
    await tester.pumpAndSettle();

    expect(find.text('缩略图时间间隔'), findsNothing);
    expect(find.text('20秒'), findsOneWidget);
    // 源缩略图步长 10 秒，选 20 秒后只剩第一张。
    expect(find.byKey(const Key('video-thumbnail-thumb-1')), findsNothing);
    expect(find.byKey(const Key('video-thumbnail-thumb-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('video-thumbnail-columns-trigger')));
    await tester.pumpAndSettle();
    expect(find.text('缩略图列数'), findsOneWidget);

    await tester.tap(find.byKey(const Key('video-thumbnail-columns-option-3')));
    await tester.pumpAndSettle();

    expect(find.text('缩略图列数'), findsNothing);
    expect(find.text('3列'), findsOneWidget);
    final grid = tester.widget<GridView>(
      find.byKey(const Key('video-thumbnail-thumbnail-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(tester.takeException(), isNull);
  });
  test(
    'video thumbnail action descriptors expose set cover only when enabled',
    () {
      final thumbnail = MovieMediaThumbnailDto(
        thumbnailId: 51,
        mediaId: 31,
        offsetSeconds: 0,
        image: const MovieImageDto(
          id: 51,
          origin: 'relative/thumb.webp',
          small: 'relative/thumb.webp',
          medium: 'relative/thumb.webp',
          large: 'relative/thumb.webp',
        ),
      );

      final movieActions = buildMediaThumbnailActionDescriptors(
        thumbnail: thumbnail,
        point: null,
      );
      final videoActions = buildMediaThumbnailActionDescriptors(
        thumbnail: thumbnail,
        point: null,
        canSetCover: true,
      );

      expect(
        movieActions.any(
          (action) => action.type == AppImageActionType.setCover,
        ),
        isFalse,
      );
      expect(
        videoActions.any(
          (action) => action.type == AppImageActionType.setCover,
        ),
        isTrue,
      );
    },
  );

  test('video playback thumbnail menu matches the JAV action set', () {
    final thumbnail = MovieMediaThumbnailDto(
      thumbnailId: 51,
      mediaId: 31,
      offsetSeconds: 0,
      image: const MovieImageDto(
        id: 51,
        origin: 'relative/thumb.webp',
        small: 'relative/thumb.webp',
        medium: 'relative/thumb.webp',
        large: 'relative/thumb.webp',
      ),
    );

    final actions = buildMediaThumbnailActionDescriptors(
      thumbnail: thumbnail,
      point: null,
    );

    expect(actions.map((action) => action.label), [
      '相似图片',
      '保存到本地',
      '添加标记',
      '播放',
    ]);
  });

  testWidgets('desktop and mobile video action surfaces show thumbnail entry', (
    tester,
  ) async {
    final video = const VideoItemListItemDto(
      id: 7,
      title: 'PornBox 测试视频',
      mediaCount: 1,
      canPlay: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: DesktopVideoActionsDialogBody(
            video: video,
            onPlay: () {},
            onThumbnails: () {},
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('desktop-video-action-thumbnails')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: MobileVideoActionsSheet(
            video: video,
            onPlay: () {},
            onThumbnails: () {},
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('mobile-video-action-thumbnails')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpVideoThumbnailPage(
  WidgetTester tester, {
  required bool mobile,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = mobile
      ? const Size(390, 844)
      : const Size(1100, 760);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final sessionStore = SessionStore.inMemory();
  await sessionStore.saveBaseUrl('https://api.example.com');
  await sessionStore.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime(2030),
  );
  final apiClient = ApiClient(sessionStore: sessionStore);
  final adapter = FakeHttpClientAdapter();
  apiClient.rawDio.httpClientAdapter = adapter;
  apiClient.rawRefreshDio.httpClientAdapter = adapter;
  addTearDown(apiClient.dispose);

  adapter.enqueueJson(
    method: 'GET',
    path: '/videos/7',
    body: _videoDetailJson(),
  );
  adapter.enqueueJson(
    method: 'GET',
    path: '/media/31/thumbnails',
    body: <Map<String, dynamic>>[
      _thumbnailJson(id: 51, offset: 0),
      _thumbnailJson(id: 52, offset: 10),
    ],
  );

  final page = mobile
      ? const AppMobileSubpageShell(
          title: '缩略图',
          defaultLocation: '/mobile/pornbox',
          bodyPadding: EdgeInsets.all(8),
          child: MobileVideoThumbnailPage(videoId: 7),
        )
      : const Scaffold(body: DesktopVideoThumbnailPage(videoId: 7));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(sessionStore),
        videosApiProvider.overrideWithValue(VideosApi(apiClient: apiClient)),
        mediaApiProvider.overrideWithValue(MediaApi(apiClient: apiClient)),
      ],
      child: OKToast(
        child: MaterialApp(
          theme: mobile ? sakuraMobileThemeData : sakuraThemeData,
          home: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _videoDetailJson() {
  return <String, dynamic>{
    'id': 7,
    'title': 'PornBox 测试视频',
    'summary': '',
    'cover_image': null,
    'release_date': null,
    'media_count': 1,
    'can_play': true,
    'media_items': <Map<String, dynamic>>[
      <String, dynamic>{
        'media_id': 31,
        'play_url': '/files/videos/7/video.mp4',
        'file_name': 'video.mp4',
        'file_size_bytes': 100,
        'duration_seconds': 120,
        'valid': true,
        'progress': null,
        'points': const <dynamic>[],
      },
    ],
  };
}

Map<String, dynamic> _thumbnailJson({required int id, required int offset}) {
  return <String, dynamic>{
    'thumbnail_id': id,
    'media_id': 31,
    'offset_seconds': offset,
    'image': <String, dynamic>{
      'id': id,
      'origin': 'relative/thumb-$id.webp',
      'small': 'relative/thumb-$id.webp',
      'medium': 'relative/thumb-$id.webp',
      'large': 'relative/thumb-$id.webp',
    },
    'width': 1280,
    'height': 720,
  };
}
