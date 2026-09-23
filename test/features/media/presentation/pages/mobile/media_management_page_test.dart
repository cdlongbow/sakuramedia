import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/configuration/data/api/media_libraries_api.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_api.dart';
import 'package:sakuramedia/features/media/presentation/pages/mobile/media_management_page.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/fake_http_client_adapter.dart';

void main() {
  late SessionStore sessionStore;
  late ApiClient apiClient;
  late FakeHttpClientAdapter adapter;
  late MediaApi mediaApi;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-05-13T12:00:00Z'),
    );
    apiClient = ApiClient(sessionStore: sessionStore);
    adapter = FakeHttpClientAdapter();
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
    mediaApi = MediaApi(apiClient: apiClient);
  });

  tearDown(() {
    apiClient.dispose();
    sessionStore.dispose();
  });

  testWidgets('renders mobile list and supported tabs', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(items: [_mediaItemJson(1)]),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(
      find.byKey(const Key('mobile-media-management-row-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-media-management-tab-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-media-management-tab-maintenance')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-media-management-tab-duplicates')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-media-management-tab-batches')),
      findsNothing,
    );
  });

  testWidgets('swiping the content switches tabs', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(items: [_mediaItemJson(1)]),
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/duplicates',
      body: _mediaPage(items: const []),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(
      find.byKey(const Key('mobile-media-management-row-1')),
      findsOneWidget,
    );
    expect(adapter.hitCount('GET', '/media/duplicates'), 0);

    await tester.drag(
      find.byKey(const Key('mobile-media-management-tab-view')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();

    expect(adapter.hitCount('GET', '/media/duplicates'), 1);
    expect(
      find.byKey(const Key('mobile-media-management-duplicate-media-section')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('mobile-media-management-tab-view')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile-media-management-row-1')),
      findsOneWidget,
    );
  });

  testWidgets('long press exposes batch transfer and delete actions', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(items: [_mediaItemJson(1)]),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.longPress(
      find.byKey(const Key('mobile-media-management-row-1')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mobile-media-management-batch-delete-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-media-management-batch-transfer-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-media-management-delete-1')),
      findsNothing,
    );
  });

  testWidgets('deletes a media item from its mobile card', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(items: [_mediaItemJson(1)]),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(
      find.byKey(const Key('mobile-media-management-delete-1')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('mobile-media-management-delete-1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('media-management-delete-dialog-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-media-management-batch-delete-button')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const Key('media-management-delete-confirm-1')),
    );
    await tester.pumpAndSettle();

    expect(adapter.hitCount('DELETE', '/media/1'), 1);
    expect(
      find.byKey(const Key('mobile-media-management-row-1')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('retries a terminal thumbnail from its mobile card', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(
        items: [_mediaItemJson(1, thumbnailGenerationState: 'terminal')],
      ),
    );
    adapter.enqueueJson(
      method: 'POST',
      path: '/media/thumbnail-generation/reset',
      body: <String, dynamic>{'reset_count': 1},
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(items: const []),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(
      find.byKey(const Key('mobile-media-management-retry-thumbnails-1')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('mobile-media-management-retry-thumbnails-1')),
    );
    await tester.pumpAndSettle();

    final resetRequest = adapter.requests.singleWhere(
      (request) =>
          request.method == 'POST' &&
          request.path == '/media/thumbnail-generation/reset',
    );
    expect(resetRequest.body, <String, dynamic>{
      'media_ids': <int>[1],
    });
    expect(
      find.byKey(const Key('mobile-media-management-row-1')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('invalid media reuses the mobile media card', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/invalid',
      body: <String, dynamic>{
        'items': [_invalidMediaJson(1)],
        'page': 1,
        'page_size': 20,
        'total': 1,
      },
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(
      find.byKey(const Key('mobile-media-management-tab-maintenance')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invalid-media-row-1')), findsOneWidget);
    expect(
      find.byKey(const Key('invalid-media-row-heading-1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('invalid-media-delete-1')), findsOneWidget);
  });

  testWidgets('batch deletes selected invalid media on mobile', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/invalid',
      body: <String, dynamic>{
        'items': [_invalidMediaJson(1), _invalidMediaJson(2)],
        'page': 1,
        'page_size': 20,
        'total': 2,
      },
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    adapter.enqueueJson(method: 'DELETE', path: '/media/2', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(
      find.byKey(const Key('mobile-media-management-tab-maintenance')),
    );
    await tester.pumpAndSettle();

    await tester.longPress(
      find.byKey(const Key('invalid-media-row-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invalid-media-row-2')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('invalid-media-batch-delete-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('invalid-media-batch-delete-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('invalid-media-batch-delete-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(adapter.hitCount('DELETE', '/media/1'), 1);
    expect(adapter.hitCount('DELETE', '/media/2'), 1);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('mobile filter opens bottom drawer', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(items: const []),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );
    await tester.tap(
      find.byKey(const Key('mobile-media-management-filter-trigger')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mobile-media-management-filter-scroll-view')),
      findsOneWidget,
    );
    expect(find.text('缩略图状态'), findsOneWidget);
  });

  testWidgets('retries selected terminal thumbnails from mobile actions', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(
        items: [_mediaItemJson(1, thumbnailGenerationState: 'terminal')],
      ),
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(
        items: [_mediaItemJson(1, thumbnailGenerationState: 'terminal')],
      ),
    );
    adapter.enqueueJson(
      method: 'POST',
      path: '/media/thumbnail-generation/reset',
      body: <String, dynamic>{'reset_count': 1},
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _mediaPage(items: const []),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(
      find.byKey(const Key('mobile-media-management-filter-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-thumbnail-generation-filter-terminal')),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();

    await tester.longPress(
      find.byKey(const Key('mobile-media-management-row-1')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const Key('mobile-media-management-batch-reset-thumbnails-button'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const Key('mobile-media-management-batch-reset-thumbnails-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('media-management-batch-reset-thumbnails-confirm-button'),
      ),
    );
    await tester.pumpAndSettle();

    final resetRequest = adapter.requests.singleWhere(
      (request) =>
          request.method == 'POST' &&
          request.path == '/media/thumbnail-generation/reset',
    );
    expect(resetRequest.body, <String, dynamic>{
      'media_ids': <int>[1],
    });
    expect(
      find.byKey(const Key('mobile-media-management-row-1')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 3));
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required SessionStore sessionStore,
  required MediaApi mediaApi,
  required ApiClient apiClient,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(sessionStore),
        mediaApiProvider.overrideWithValue(mediaApi),
        mediaLibrariesApiProvider.overrideWithValue(
          _EmptyMediaLibrariesApi(apiClient: apiClient),
        ),
      ],
      child: MaterialApp(
        theme: sakuraThemeData,
        home: const OKToast(child: Scaffold(body: MobileMediaManagementPage())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _EmptyMediaLibrariesApi extends MediaLibrariesApi {
  const _EmptyMediaLibrariesApi({required super.apiClient});

  @override
  Future<List<MediaLibraryDto>> getLibraries() async =>
      const <MediaLibraryDto>[];
}

Map<String, dynamic> _mediaPage({required List<Map<String, dynamic>> items}) {
  return <String, dynamic>{
    'items': items,
    'page': 1,
    'page_size': 30,
    'total': items.length,
  };
}

Map<String, dynamic> _mediaItemJson(
  int id, {
  String thumbnailGenerationState = 'succeeded',
}) {
  return <String, dynamic>{
    'id': id,
    'kind': 'jav',
    'movie_number': 'ABC-$id',
    'video_item_id': null,
    'title': 'Movie $id',
    'cover_image': null,
    'thin_cover_image': null,
    'library_id': 1,
    'library_name': 'Main',
    'file_name': 'abc-$id.mp4',
    'file_size_bytes': 100,
    'duration_seconds': 60,
    'resolution': '1920x1080',
    'valid': true,
    'thumbnail_generation_state': thumbnailGenerationState,
    'thumbnail_last_error_code': null,
    'heat': 100,
    'created_at': '2026-03-12T10:00:00Z',
    'updated_at': '2026-03-12T10:00:00Z',
  };
}

Map<String, dynamic> _invalidMediaJson(int id) {
  return <String, dynamic>{
    'id': id,
    'movie_number': 'ABC-$id',
    'video_item_id': null,
    'movie_title': 'Movie $id',
    'cover_image': null,
    'thin_cover_image': null,
    'file_name': 'ABC-$id.mp4',
    'library_id': 1,
    'library_name': 'Main Library',
    'file_size_bytes': 1024,
    'updated_at': '2026-05-13T12:00:00Z',
  };
}
