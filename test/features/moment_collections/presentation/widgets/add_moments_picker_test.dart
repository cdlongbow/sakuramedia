import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/media/data/media_api.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/moment_collections/data/api/moment_collections_api.dart';
import 'package:sakuramedia/features/moment_collections/presentation/providers/moment_collections_api_provider.dart';
import 'package:sakuramedia/features/moment_collections/presentation/widgets/add_moments_to_collection_dialog.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../support/fake_http_client_adapter.dart';

Map<String, dynamic> _mediaPointJson(int pointId) => <String, dynamic>{
  'point_id': pointId,
  'media_id': 100 + pointId,
  'movie_number': 'ABC-${pointId.toString().padLeft(3, '0')}',
  'video_item_id': null,
  'thumbnail_id': 200 + pointId,
  'offset_seconds': pointId * 10,
  'image': null,
  'created_at': '2026-09-10T10:00:00Z',
};

ResponseBody _pointsPageBody(
  List<int> pointIds, {
  required int page,
  required int total,
}) {
  return ResponseBody.fromString(
    jsonEncode(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        for (final pointId in pointIds) _mediaPointJson(pointId),
      ],
      'page': page,
      'page_size': 24,
      'total': total,
    }),
    200,
    headers: const <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

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
    sessionStore.dispose();
  });

  void enqueuePoints({
    required List<int> pointIds,
    int? total,
  }) {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media-points',
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          for (final pointId in pointIds) _mediaPointJson(pointId),
        ],
        'page': 1,
        'page_size': 24,
        'total': total ?? pointIds.length,
      },
    );
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    bool mobile = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = mobile ? const Size(390, 844) : const Size(1100, 760);
    addTearDown(tester.view.reset);

    late BuildContext pickerContext;
    final app = OKToast(
      child: MaterialApp(
        theme: sakuraThemeData,
        home: Builder(
          builder: (context) {
            pickerContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(sessionStore),
          momentCollectionsApiProvider.overrideWithValue(
            MomentCollectionsApi(apiClient: apiClient),
          ),
          mediaApiProvider.overrideWithValue(MediaApi(apiClient: apiClient)),
        ],
        retry: (_, _) => null,
        child: mobile
            ? AppPlatformScope(platform: AppPlatform.mobile, child: app)
            : app,
      ),
    );
    unawaited(
      showAddMomentsToCollectionDialog(
        pickerContext,
        collectionId: 7,
        memberPointIds: const <int>{10},
      ),
    );
    await tester.pumpAndSettle();
  }

  Text countLabel(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('add-moments-count')));

  testWidgets('默认仅看未加入并携带 kind=all 与 exclude_collection_id', (tester) async {
    enqueuePoints(pointIds: const [12, 13]);
    await pumpPicker(tester);

    final params = adapter.requests.last.uri.queryParameters;
    expect(params['kind'], 'all');
    expect(params['exclude_collection_id'], '7');
    expect(params['page'], '1');
    expect(countLabel(tester).data, '已加入 1 · 可添加 2');
    expect(find.byKey(const Key('add-moments-option-12')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换内容类型与仅看未加入都会重发请求', (tester) async {
    enqueuePoints(pointIds: const [12]);
    await pumpPicker(tester);

    enqueuePoints(pointIds: const [12]);
    await tester.tap(find.byKey(const Key('add-moments-kind-jav')));
    await tester.pumpAndSettle();
    expect(adapter.requests.last.uri.queryParameters['kind'], 'jav');

    enqueuePoints(pointIds: const [10, 12]);
    await tester.tap(find.byKey(const Key('add-moments-only-unadded-chip')));
    await tester.pumpAndSettle();
    final params = adapter.requests.last.uri.queryParameters;
    expect(params.containsKey('exclude_collection_id'), isFalse);
    expect(params['kind'], 'jav');
    expect(countLabel(tester).data, '已加入 1 · 共 2');

    final checkbox = tester.widget<Checkbox>(
      find.byKey(const Key('add-moments-checkbox-10')),
    );
    expect(checkbox.value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索输入防抖后才发起请求', (tester) async {
    enqueuePoints(pointIds: const [12]);
    await pumpPicker(tester);
    final before = adapter.requests.length;

    await tester.enterText(
      find.byKey(const Key('add-moments-search-field')),
      '天台',
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(adapter.requests.length, before);

    enqueuePoints(pointIds: const [12]);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(adapter.requests.length, before + 1);
    expect(adapter.requests.last.uri.queryParameters['keyword'], '天台');

    // 清空按钮恢复全量列表（不带 keyword）。
    enqueuePoints(pointIds: const [12, 13]);
    await tester.tap(find.byKey(const Key('add-moments-search-clear')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.last.uri.queryParameters.containsKey('keyword'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('仅未加入模式下加入即出池计数减一', (tester) async {
    enqueuePoints(pointIds: const [12]);
    await pumpPicker(tester);

    adapter.enqueueJson(
      method: 'PUT',
      path: '/moment-collections/7/points/12',
      statusCode: 204,
    );
    await tester.tap(find.byKey(const Key('add-moments-option-12')));
    await tester.pumpAndSettle();

    expect(adapter.hitCount('PUT', '/moment-collections/7/points/12'), 1);
    expect(find.byKey(const Key('add-moments-option-12')), findsNothing);
    expect(countLabel(tester).data, '已加入 2 · 可添加 0');
    expect(
      find.byKey(const Key('add-moments-empty-all-added')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('全部已加入空态可一键切回全部', (tester) async {
    enqueuePoints(pointIds: const [], total: 0);
    await pumpPicker(tester);

    expect(
      find.byKey(const Key('add-moments-empty-all-added')),
      findsOneWidget,
    );

    enqueuePoints(pointIds: const [10]);
    await tester.tap(find.byKey(const Key('add-moments-show-all-button')));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.last.uri.queryParameters.containsKey(
        'exclude_collection_id',
      ),
      isFalse,
    );
    expect(find.byKey(const Key('add-moments-option-10')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('加入出池后继续加载不会漏掉边界项', (tester) async {
    enqueuePoints(
      pointIds: List<int>.generate(24, (i) => 100 + i),
      total: 48,
    );
    await pumpPicker(tester);

    adapter.enqueueJson(
      method: 'PUT',
      path: '/moment-collections/7/points/100',
      statusCode: 204,
    );
    await tester.tap(find.byKey(const Key('add-moments-option-100')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 加入后服务端过滤集缩小一条：page 1 变成 x0..x4,x6..x23,x24，
    // page 2 从 x25 开始。修复前客户端直接请求 page 2，x24 会被永久漏掉。
    final serverIds = <int>[
      ...List<int>.generate(5, (i) => 100 + i),
      ...List<int>.generate(18, (i) => 106 + i),
      124,
      ...List<int>.generate(23, (i) => 125 + i),
    ];
    adapter.enqueueResponder(
      method: 'GET',
      path: '/media-points',
      responder: (RequestOptions options, dynamic _) async {
        final page = int.parse(options.uri.queryParameters['page'] ?? '1');
        final start = (page - 1) * 24;
        return _pointsPageBody(
          serverIds.skip(start).take(24).toList(),
          page: page,
          total: serverIds.length,
        );
      },
    );

    final firstLoadMoreIndex = adapter.requests.length;
    var found = false;
    final list = find.byKey(const Key('add-moments-list'));
    for (var i = 0; i < 8 && !found; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      found = find
          .byKey(const Key('add-moments-option-124'))
          .evaluate()
          .isNotEmpty;
    }

    expect(adapter.requests.length, greaterThan(firstLoadMoreIndex));
    expect(
      adapter.requests[firstLoadMoreIndex].uri.queryParameters['page'],
      '1',
    );
    expect(find.byKey(const Key('add-moments-option-124')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('移动抽屉显示完成按钮并关闭抽屉', (tester) async {
    enqueuePoints(pointIds: const [12]);
    await pumpPicker(tester, mobile: true);

    expect(find.byKey(const Key('add-moments-done-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-moments-done-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-moments-list')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
