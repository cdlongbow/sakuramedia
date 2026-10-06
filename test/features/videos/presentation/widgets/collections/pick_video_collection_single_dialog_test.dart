import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/pick_video_collection_single_dialog.dart';
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

  void enqueueCollections() {
    adapter.enqueueJson(
      method: 'GET',
      path: '/video-collections',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 3,
          'name': '系列 A',
          'description': '',
          'item_count': 2,
          'cover_image': null,
        },
        <String, dynamic>{
          'id': 5,
          'name': '系列 B',
          'description': '',
          'item_count': 0,
          'cover_image': null,
        },
      ],
    );
  }

  Future<VideoCollectionSelection? Function()> pumpHost(
    WidgetTester tester, {
    required int? selectedCollectionId,
  }) async {
    VideoCollectionSelection? picked;
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
              body: Builder(
                builder: (context) => TextButton(
                  key: const Key('open-single-picker'),
                  onPressed: () async {
                    picked = await showPickVideoCollectionSingleDialog(
                      context,
                      selectedCollectionId: selectedCollectionId,
                    );
                  },
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return () => picked;
  }

  testWidgets('回显已选合集并支持搜索后单选', (WidgetTester tester) async {
    enqueueCollections();
    final picked = await pumpHost(tester, selectedCollectionId: 3);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-single-picker')));
    await tester.pumpAndSettle();

    // 回显：当前合集勾选，「不加入合集」未选。
    expect(
      tester
          .widget<Checkbox>(
            find.byKey(const Key('pick-video-collection-single-checkbox-3')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Checkbox>(
            find.byKey(const Key('pick-video-collection-single-none-checkbox')),
          )
          .value,
      isFalse,
    );

    // 搜索过滤。
    await tester.enterText(
      find.byKey(const Key('pick-video-collection-single-search-field')),
      '系列 B',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pick-video-collection-single-3')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('pick-video-collection-single-5')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('pick-video-collection-single-5')));
    await tester.pumpAndSettle();

    expect(picked()?.collectionId, 5);
  });

  testWidgets('搜索无结果仍可选「不加入合集」', (WidgetTester tester) async {
    enqueueCollections();
    final picked = await pumpHost(tester, selectedCollectionId: 3);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-single-picker')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pick-video-collection-single-search-field')),
      '不存在',
    );
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的合集'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pick-video-collection-single-none')),
    );
    await tester.pumpAndSettle();

    // 返回结果对象但 collectionId 为 null（与整个弹层取消区分）。
    final result = picked();
    expect(result, isNotNull);
    expect(result?.collectionId, isNull);
  });
}
