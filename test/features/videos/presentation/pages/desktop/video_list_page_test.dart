import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/data/api/videos_api.dart';
import 'package:sakuramedia/features/videos/presentation/pages/desktop/video_list_page.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_toolbar.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_filter_entry_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/domain/collections/collection_card.dart';

import '../../../../../support/fake_http_client_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late ApiClient apiClient;
  late FakeHttpClientAdapter adapter;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    apiClient = ApiClient(sessionStore: sessionStore);
    adapter = FakeHttpClientAdapter();
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
  });

  tearDown(() {
    apiClient.dispose();
  });

  void enqueueInitialLoad({int total = 2}) {
    adapter.enqueueJson(
      method: 'GET',
      path: '/video-collections',
      body: <Map<String, dynamic>>[],
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/videos',
      body: _videosJson(total: total),
    );
  }

  testWidgets('桌面 PornBox 顶栏与移动端同构：筛选入口 + 总数 + 选择入口', (
    WidgetTester tester,
  ) async {
    enqueueInitialLoad();

    await _pumpVideoListPage(
      tester,
      sessionStore: sessionStore,
      apiClient: apiClient,
    );
    await tester.pumpAndSettle();

    // 顶栏收敛到 AppListHeader，旧的 AppFilterTotalHeader 不再出现。
    expect(find.byType(AppListHeader), findsOneWidget);
    expect(find.byType(AppFilterTotalHeader), findsNothing);

    // 筛选入口只报合集归属；排序是独立的第二个入口。
    final entry = tester.widget<AppFilterEntryButton>(
      find.descendant(
        of: find.byKey(const Key('videos-filter-trigger')),
        matching: find.byType(AppFilterEntryButton),
      ),
    );
    expect(entry.label, '全部');
    expect(find.byKey(const Key('videos-sort-trigger')), findsOneWidget);

    // 总数走只读信息胶囊；「选择」在右侧操作槽。
    expect(find.byKey(const Key('videos-page-total')), findsOneWidget);
    expect(find.text('2 个'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('app-list-header-action-slots')),
        matching: find.byKey(const Key('videos-enter-selection-button')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('桌面 PornBox 合集首屏加载显示卡片骨架', (WidgetTester tester) async {
    final pendingCollections = Completer<ResponseBody>();
    adapter.enqueueResponder(
      method: 'GET',
      path: '/video-collections',
      responder: (_, __) => pendingCollections.future,
    );
    adapter.enqueueJson(method: 'GET', path: '/videos', body: _videosJson());

    await _pumpVideoListPage(
      tester,
      sessionStore: sessionStore,
      apiClient: apiClient,
    );
    await tester.pump();

    expect(find.byType(AppSkeletonizer), findsWidgets);
    // 加载态渲染的是真实合集卡（占位数据），骨架即真实布局。
    expect(find.byKey(const Key('videos-collections-row')), findsOneWidget);
    expect(find.byType(CollectionCard), findsNWidgets(4));
    expect(find.byType(CircularProgressIndicator), findsNothing);

    pendingCollections.complete(
      ResponseBody.fromString(
        '[]',
        200,
        headers: const <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('进入多选原地改写整条顶栏，不另起一行且高度不变', (WidgetTester tester) async {
    enqueueInitialLoad();

    await _pumpVideoListPage(
      tester,
      sessionStore: sessionStore,
      apiClient: apiClient,
    );
    await tester.pumpAndSettle();

    final headerHeight = tester
        .getSize(find.byType(AppListHeader).first)
        .height;

    await tester.tap(find.byKey(const Key('videos-enter-selection-button')));
    await tester.pumpAndSettle();

    // 常规顶栏被替换掉，而不是在它下方再加一行。
    expect(find.byType(AppListHeader), findsNothing);
    expect(find.byType(AppSelectionHeaderToolbar), findsOneWidget);
    expect(find.byKey(const Key('videos-select-all-button')), findsOneWidget);
    expect(
      find.byKey(const Key('videos-batch-add-collection-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('videos-batch-delete-button')), findsOneWidget);

    // 进出多选不跳版：两态高度一致（与影片列表同一条规则）。
    expect(
      tester.getSize(find.byType(AppSelectionHeaderToolbar)).height,
      headerHeight,
    );

    await tester.tap(find.byKey(const Key('videos-exit-selection-button')));
    await tester.pumpAndSettle();

    expect(find.byType(AppListHeader), findsOneWidget);
    expect(find.byType(AppSelectionHeaderToolbar), findsNothing);
  });

  testWidgets('桌面筛选与排序入口分离，点选排序即时生效', (WidgetTester tester) async {
    enqueueInitialLoad();

    await _pumpVideoListPage(
      tester,
      sessionStore: sessionStore,
      apiClient: apiClient,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('videos-filter-trigger')));
    await tester.pumpAndSettle();

    // 筛选面板只保留合集归属，排序不在其中。
    expect(find.byKey(const Key('videos-filter-panel')), findsOneWidget);
    expect(find.text('合集'), findsOneWidget);
    expect(find.text('排序字段'), findsNothing);
    expect(find.text('升降序'), findsNothing);
    expect(find.text('确定'), findsNothing);

    await tester.tap(find.byKey(const Key('videos-filter-trigger')));
    await tester.pumpAndSettle();

    adapter.enqueueJson(
      method: 'GET',
      path: '/videos',
      body: _videosJson(total: 1),
    );

    await tester.tap(find.byKey(const Key('videos-sort-trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('videos-sort-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('videos-sort-field-title')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 即时生效：点选当场触发带新排序的重新拉取。
    final lastRequest = adapter.requests.lastWhere(
      (request) => request.uri.path == '/videos',
    );
    expect(lastRequest.uri.queryParameters['sort'], startsWith('title:'));
    expect(find.text('1 个'), findsOneWidget);
  });

  testWidgets('桌面筛选浮层「未加入合集」即时生效并携带 uncollected', (
    WidgetTester tester,
  ) async {
    enqueueInitialLoad();

    await _pumpVideoListPage(
      tester,
      sessionStore: sessionStore,
      apiClient: apiClient,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('videos-filter-trigger')));
    await tester.pumpAndSettle();

    // 面板新增「合集」分节，与排序分节同构。
    expect(find.text('合集'), findsOneWidget);
    expect(find.text('未加入合集'), findsOneWidget);
    expect(find.byKey(const Key('videos-filter-collection-all')), findsOneWidget);

    adapter.enqueueJson(
      method: 'GET',
      path: '/videos',
      body: _videosJson(total: 1),
    );

    await tester.tap(
      find.byKey(const Key('videos-filter-collection-uncollected')),
    );
    await tester.pumpAndSettle();

    final lastRequest = adapter.requests.last;
    expect(lastRequest.path, '/videos');
    expect(lastRequest.uri.queryParameters['uncollected'], 'true');
    expect(find.text('1 个'), findsOneWidget);
  });

  void enqueueBatchAccepted() {
    adapter.enqueueJson(
      method: 'POST',
      path: '/batch-operations',
      statusCode: 202,
      body: <String, dynamic>{
        'task_run_id': 7,
        'task_key': 'batch_operation',
        'state': 'pending',
      },
    );
  }

  testWidgets('批量删除视频提交 video_delete 且 ids 是 video id', (
    WidgetTester tester,
  ) async {
    enqueueInitialLoad();
    enqueueBatchAccepted();

    await _pumpVideoListPage(
      tester,
      sessionStore: sessionStore,
      apiClient: apiClient,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('videos-enter-selection-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('video-summary-card-select-1')));
    await tester.tap(find.byKey(const Key('video-summary-card-select-2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('videos-batch-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('videos-batch-delete-confirm-button')),
    );
    await tester.pumpAndSettle();

    final submit = adapter.requests
        .where((request) => request.path == '/batch-operations')
        .toList();
    expect(submit, hasLength(1));
    expect(submit.single.body, {
      'operation': 'video_delete',
      'ids': [1, 2],
      'delete_files': false,
    });
    expect(adapter.hitCount('DELETE', '/videos/1'), 0);
    // 提交后列表不即时变化，等任务完成后手动刷新。
    expect(find.byKey(const Key('video-summary-card-1')), findsOneWidget);
    expect(find.byType(AppSelectionHeaderToolbar), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('批量加入视频合集提交 video_collection_add 且 ids 是 video id', (
    WidgetTester tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/video-collections',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 7,
          'name': '我的合集',
          'description': '',
          'item_count': 1,
          'cover_image': null,
        },
      ],
    );
    adapter.enqueueJson(method: 'GET', path: '/videos', body: _videosJson(total: 2));
    enqueueBatchAccepted();

    await _pumpVideoListPage(
      tester,
      sessionStore: sessionStore,
      apiClient: apiClient,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('videos-enter-selection-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('video-summary-card-select-1')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('videos-batch-add-collection-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-collection-7')));
    await tester.pumpAndSettle();

    final submit = adapter.requests
        .where((request) => request.path == '/batch-operations')
        .toList();
    expect(submit, hasLength(1));
    expect(submit.single.body, {
      'operation': 'video_collection_add',
      'ids': [1],
      'target_collection_id': 7,
      'delete_files': false,
    });
    expect(
      adapter.hitCount('PUT', '/video-collections/7/videos/1'),
      0,
    );
    expect(find.byType(AppSelectionHeaderToolbar), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpVideoListPage(
  WidgetTester tester, {
  required SessionStore sessionStore,
  required ApiClient apiClient,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 1400);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        sessionStoreProvider.overrideWithValue(sessionStore),
        videosApiProvider.overrideWithValue(VideosApi(apiClient: apiClient)),
        videoCollectionsApiProvider.overrideWithValue(
          VideoCollectionsApi(apiClient: apiClient),
        ),
      ],
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const Scaffold(body: DesktopVideoListPage()),
        ),
      ),
    ),
  );
}

Map<String, dynamic> _videosJson({
  int page = 1,
  int pageSize = 20,
  int total = 2,
}) {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      for (var index = 0; index < total; index++) _videoItem(id: index + 1),
    ],
    'page': page,
    'page_size': pageSize,
    'total': total,
  };
}

Map<String, dynamic> _videoItem({int id = 1}) {
  return <String, dynamic>{
    'id': id,
    'title': '视频 $id',
    'summary': '',
    'cover_image': null,
    'release_date': null,
    'duration_seconds': 0,
    'file_size_bytes': 0,
    'media_count': 1,
    'can_play': true,
    'collections': <Map<String, dynamic>>[],
    'created_at': null,
    'updated_at': null,
  };
}
