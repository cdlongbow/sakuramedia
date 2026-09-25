import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/data/api/videos_api.dart';
import 'package:sakuramedia/features/videos/presentation/pages/mobile/pornbox_page.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/listing/video_summary_card.dart';
import 'package:sakuramedia/theme.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(sessionStore),
          videosApiProvider.overrideWithValue(VideosApi(apiClient: apiClient)),
          videoCollectionsApiProvider.overrideWithValue(
            VideoCollectionsApi(apiClient: apiClient),
          ),
        ],
        child: OKToast(
          child: MaterialApp(
            theme: sakuraMobileThemeData,
            home: const Scaffold(body: MobilePornboxPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('进入选择保留视频合集横滑区且网格位置不变', (WidgetTester tester) async {
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
    adapter.enqueueJson(
      method: 'GET',
      path: '/videos',
      body: _videosJson(total: 2),
    );

    await pumpPage(tester);

    expect(
      find.byKey(const Key('mobile-pornbox-collections-row')),
      findsOneWidget,
    );
    expect(find.byType(CollectionCard), findsOneWidget);

    final cardTop = tester.getTopLeft(find.byType(VideoSummaryCard).first).dy;

    // 长按卡片菜单进入选择模式。
    await tester.longPress(find.byType(VideoSummaryCard).first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('mobile-pornbox-card-menu-select-item')),
    );
    await tester.pumpAndSettle();

    // 选择态原地改写顶栏：合集横滑区保留，网格位置不变。
    expect(find.text('已选 1 个'), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-pornbox-collections-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-pornbox-batch-bottom-bar')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byType(VideoSummaryCard).first).dy,
      closeTo(cardTop, 0.1),
    );

    await tester.tap(
      find.byKey(const Key('mobile-pornbox-exit-selection-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile-pornbox-batch-bottom-bar')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _videosJson({int total = 2}) {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      for (var index = 0; index < total; index++) _videoItem(id: index + 1),
    ],
    'page': 1,
    'page_size': 20,
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
