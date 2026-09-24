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
import 'package:sakuramedia/features/clip_collections/data/api/clip_collections_api.dart';
import 'package:sakuramedia/features/clip_collections/presentation/providers/clip_collections_api_provider.dart';
import 'package:sakuramedia/features/clip_collections/presentation/widgets/add_clips_to_collection_dialog.dart';
import 'package:sakuramedia/features/clips/data/api/clips_api.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_api_provider.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../support/fake_http_client_adapter.dart';

Map<String, dynamic> _clipJson(int clipId) => <String, dynamic>{
  'clip_id': clipId,
  'media_id': 100 + clipId,
  'movie_number': 'ABC-${clipId.toString().padLeft(3, '0')}',
  'start_offset_seconds': 0,
  'end_offset_seconds': 10,
  'title': '切片 $clipId',
  'duration_seconds': 10,
  'file_size_bytes': 1024,
  'cover_image': null,
  'stream_url': '/media-clips/$clipId/stream',
  'created_at': '2026-09-10T10:00:00Z',
};

ResponseBody _clipsPageBody(
  List<int> clipIds, {
  required int page,
  required int total,
}) {
  return ResponseBody.fromString(
    jsonEncode(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        for (final clipId in clipIds) _clipJson(clipId),
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

  void enqueueClips({required List<int> clipIds, int? total}) {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media-clips',
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          for (final clipId in clipIds) _clipJson(clipId),
        ],
        'page': 1,
        'page_size': 24,
        'total': total ?? clipIds.length,
      },
    );
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    bool mobile = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize =
        mobile ? const Size(390, 844) : const Size(1100, 760);
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
          clipCollectionsApiProvider.overrideWithValue(
            ClipCollectionsApi(apiClient: apiClient),
          ),
          clipsApiProvider.overrideWithValue(ClipsApi(apiClient: apiClient)),
        ],
        retry: (_, _) => null,
        child: mobile
            ? AppPlatformScope(platform: AppPlatform.mobile, child: app)
            : app,
      ),
    );
    unawaited(
      showAddClipsToCollectionDialog(
        pickerContext,
        collectionId: 7,
        memberClipIds: const <int>{10},
      ),
    );
    await tester.pumpAndSettle();
  }

  Text countLabel(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('add-clips-count')));

  testWidgets('默认仅看未加入并携带 exclude_collection_id', (tester) async {
    enqueueClips(clipIds: const [12, 13]);
    await pumpPicker(tester);

    final params = adapter.requests.last.uri.queryParameters;
    expect(params['exclude_collection_id'], '7');
    expect(params.containsKey('kind'), isFalse);
    expect(countLabel(tester).data, '已加入 1 · 可添加 2');
    expect(find.byKey(const Key('add-clips-option-12')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('仅未加入模式下加入即出池，「全部」里可取消移出', (tester) async {
    enqueueClips(clipIds: const [12]);
    await pumpPicker(tester);

    adapter.enqueueJson(
      method: 'PUT',
      path: '/clip-collections/7/clips/12',
      statusCode: 204,
    );
    await tester.tap(find.byKey(const Key('add-clips-option-12')));
    await tester.pumpAndSettle();
    expect(adapter.hitCount('PUT', '/clip-collections/7/clips/12'), 1);
    expect(find.byKey(const Key('add-clips-option-12')), findsNothing);

    enqueueClips(clipIds: const [10, 12]);
    await tester.tap(find.byKey(const Key('add-clips-only-unadded-chip')));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.last.uri.queryParameters.containsKey(
        'exclude_collection_id',
      ),
      isFalse,
    );
    final checkbox = tester.widget<Checkbox>(
      find.byKey(const Key('add-clips-checkbox-12')),
    );
    expect(checkbox.value, isTrue);

    adapter.enqueueJson(
      method: 'DELETE',
      path: '/clip-collections/7/clips/12',
      statusCode: 204,
    );
    await tester.tap(find.byKey(const Key('add-clips-option-12')));
    await tester.pumpAndSettle();
    expect(adapter.hitCount('DELETE', '/clip-collections/7/clips/12'), 1);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索输入防抖后才发起请求', (tester) async {
    enqueueClips(clipIds: const [12]);
    await pumpPicker(tester);
    final before = adapter.requests.length;

    await tester.enterText(
      find.byKey(const Key('add-clips-search-field')),
      '天台',
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(adapter.requests.length, before);

    enqueueClips(clipIds: const [12]);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(adapter.requests.length, before + 1);
    expect(adapter.requests.last.uri.queryParameters['keyword'], '天台');

    // 清空按钮恢复全量列表（不带 keyword）。
    enqueueClips(clipIds: const [12, 13]);
    await tester.tap(find.byKey(const Key('add-clips-search-clear')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.last.uri.queryParameters.containsKey('keyword'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('加入出池后继续加载不会漏掉边界项', (tester) async {
    enqueueClips(clipIds: List<int>.generate(24, (i) => 100 + i), total: 48);
    await pumpPicker(tester);

    adapter.enqueueJson(
      method: 'PUT',
      path: '/clip-collections/7/clips/100',
      statusCode: 204,
    );
    await tester.tap(find.byKey(const Key('add-clips-option-100')));
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
      path: '/media-clips',
      responder: (RequestOptions options, dynamic _) async {
        final page = int.parse(options.uri.queryParameters['page'] ?? '1');
        final start = (page - 1) * 24;
        return _clipsPageBody(
          serverIds.skip(start).take(24).toList(),
          page: page,
          total: serverIds.length,
        );
      },
    );

    final firstLoadMoreIndex = adapter.requests.length;
    var found = false;
    final list = find.byKey(const Key('add-clips-list'));
    for (var i = 0; i < 8 && !found; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      found = find
          .byKey(const Key('add-clips-option-124'))
          .evaluate()
          .isNotEmpty;
    }

    expect(adapter.requests.length, greaterThan(firstLoadMoreIndex));
    expect(
      adapter.requests[firstLoadMoreIndex].uri.queryParameters['page'],
      '1',
    );
    expect(find.byKey(const Key('add-clips-option-124')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('移动抽屉显示完成按钮并关闭抽屉', (tester) async {
    enqueueClips(clipIds: const [12]);
    await pumpPicker(tester, mobile: true);

    expect(find.byKey(const Key('add-clips-done-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-clips-done-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-clips-list')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
