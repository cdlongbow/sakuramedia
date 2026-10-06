import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/presentation/pages/mobile/video_collections_page.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/video-collections',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'name': '合集 一',
          'description': '',
          'item_count': 1,
          'cover_image': null,
        },
        <String, dynamic>{
          'id': 2,
          'name': '合集 二',
          'description': '',
          'item_count': 2,
          'cover_image': null,
        },
      ],
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
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
            home: const Scaffold(body: MobileVideoCollectionsPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('搜索按名称过滤合集卡片', (WidgetTester tester) async {
    await pumpPage(tester);

    expect(find.text('合集 一'), findsOneWidget);
    expect(find.text('合集 二'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('mobile-video-collections-search-field')),
      '二',
    );
    await tester.pumpAndSettle();

    expect(find.text('合集 一'), findsNothing);
    expect(find.text('合集 二'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('mobile-video-collections-search-field')),
      '不存在',
    );
    await tester.pumpAndSettle();

    expect(find.text('没有匹配的合集'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
