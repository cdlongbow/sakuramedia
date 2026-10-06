import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/data/dto/video_item_list_item_dto.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/add_to_video_collection_dialog.dart';
import 'package:sakuramedia/theme.dart';

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

  Map<String, dynamic> collectionJson(int id, String name, int itemCount) {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': '',
      'item_count': itemCount,
      'cover_image': null,
    };
  }

  void enqueueCollections() {
    adapter.enqueueJson(
      method: 'GET',
      path: '/video-collections',
      body: <Map<String, dynamic>>[
        collectionJson(3, '系列 A', 2),
        collectionJson(5, '系列 B', 0),
      ],
    );
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    List<VideoCollectionRef> collectedRefs = const <VideoCollectionRef>[],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 700);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoCollectionsApiProvider.overrideWithValue(
            VideoCollectionsApi(apiClient: apiClient),
          ),
        ],
        child: OKToast(
          child: MaterialApp(
            theme: sakuraMobileThemeData,
            home: Scaffold(
              body: AddToVideoCollectionDialog(
                videoItemId: 101,
                collectedRefs: collectedRefs,
                presentation: AddToVideoCollectionPresentation.bottomDrawer,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Checkbox checkboxOf(WidgetTester tester, int collectionId) {
    return tester.widget<Checkbox>(
      find.byKey(Key('add-to-video-collection-checkbox-$collectionId')),
    );
  }

  testWidgets('打开时回显已加入的合集为勾选态', (WidgetTester tester) async {
    enqueueCollections();

    await pumpDialog(
      tester,
      collectedRefs: const <VideoCollectionRef>[
        VideoCollectionRef(id: 3, name: '系列 A'),
      ],
    );

    expect(checkboxOf(tester, 3).value, isTrue);
    expect(checkboxOf(tester, 5).value, isFalse);
  });

  testWidgets('点未勾选行加入、点已勾选行按视频移出', (WidgetTester tester) async {
    enqueueCollections();
    adapter.enqueueJson(
      method: 'POST',
      path: '/video-collections/5/items',
      statusCode: 204,
    );
    adapter.enqueueJson(
      method: 'DELETE',
      path: '/video-collections/3/videos/101',
      statusCode: 204,
    );

    await pumpDialog(
      tester,
      collectedRefs: const <VideoCollectionRef>[
        VideoCollectionRef(id: 3, name: '系列 A'),
      ],
    );

    await tester.tap(
      find.byKey(const Key('add-to-video-collection-option-5')),
    );
    await tester.pumpAndSettle();

    expect(checkboxOf(tester, 5).value, isTrue);
    final addRequest = adapter.requests.singleWhere(
      (request) => request.method == 'POST',
    );
    expect(addRequest.path, '/video-collections/5/items');
    expect(addRequest.body, <String, dynamic>{'video_item_id': 101});

    await tester.tap(
      find.byKey(const Key('add-to-video-collection-option-3')),
    );
    await tester.pumpAndSettle();

    expect(checkboxOf(tester, 3).value, isFalse);
    expect(adapter.hitCount('DELETE', '/video-collections/3/videos/101'), 1);
  });

  testWidgets('移出失败回滚勾选态', (WidgetTester tester) async {
    enqueueCollections();
    adapter.enqueueJson(
      method: 'DELETE',
      path: '/video-collections/3/videos/101',
      statusCode: 500,
      body: <String, dynamic>{'detail': 'boom'},
    );

    await pumpDialog(
      tester,
      collectedRefs: const <VideoCollectionRef>[
        VideoCollectionRef(id: 3, name: '系列 A'),
      ],
    );

    await tester.tap(
      find.byKey(const Key('add-to-video-collection-option-3')),
    );
    await tester.pumpAndSettle();

    // 请求失败：勾选态回滚为「已加入」。
    expect(checkboxOf(tester, 3).value, isTrue);
    // 等失败 toast 的计时器走完，避免测试结束时残留 pending timer。
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('搜索按名称过滤合集且无结果给出提示', (WidgetTester tester) async {
    enqueueCollections();

    await pumpDialog(tester);

    await tester.enterText(
      find.byKey(const Key('add-to-video-collection-search-field')),
      '系列 B',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('add-to-video-collection-option-3')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('add-to-video-collection-option-5')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('add-to-video-collection-search-field')),
      '不存在',
    );
    await tester.pumpAndSettle();

    expect(find.text('没有匹配的合集'), findsOneWidget);
  });
}
