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
import 'package:sakuramedia/features/media/presentation/pages/desktop/media_management_page.dart';
import 'package:sakuramedia/features/media/presentation/pages/shared/media_management_content.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_mutation_events_provider.dart';
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
    adapter.setFallbackJson(method: 'GET', path: '/media', body: _emptyPage());
  });

  tearDown(() {
    apiClient.dispose();
    sessionStore.dispose();
  });

  testWidgets('renders supported tabs and lazy-loads management sections', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/duplicates',
      body: _page(total: 0, items: const []),
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/invalid',
      body: _page(total: 0, items: const []),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(find.byKey(const Key('media-management-tab-list')), findsOneWidget);
    expect(
      find.byKey(const Key('media-management-tab-maintenance')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('media-management-tab-duplicates')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('media-management-tab-batches')), findsNothing);
    expect(adapter.hitCount('GET', '/media/duplicates'), 0);
    expect(adapter.hitCount('GET', '/media/invalid'), 0);

    await tester.tap(find.byKey(const Key('media-management-tab-duplicates')));
    await tester.pumpAndSettle();
    expect(adapter.hitCount('GET', '/media/duplicates'), 1);
    expect(
      find.byKey(const Key('media-management-duplicate-media-section')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('media-management-tab-maintenance')));
    await tester.pumpAndSettle();
    expect(adapter.hitCount('GET', '/media/invalid'), 1);
    expect(
      find.byKey(const Key('media-management-invalid-media-section')),
      findsOneWidget,
    );
  });

  testWidgets('shows duplicate groups and removes the final duplicate copy', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/duplicates',
      body: _page(total: 1, items: [_duplicateGroupJson()]),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(find.byKey(const Key('media-management-tab-duplicates')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('media-management-duplicate-group-1')),
      findsOneWidget,
    );
    expect(find.text('abc-1.mp4'), findsOneWidget);
    expect(find.text('重复文件组'), findsNothing);
    expect(find.text('以下媒体内容相同，分别来自不同媒体记录。'), findsNothing);
    expect(find.textContaining('hash'), findsNothing);

    await tester.tap(
      find.byKey(const Key('media-management-duplicate-delete-1')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('media-management-duplicate-delete-dialog-1')),
      findsOneWidget,
    );
    expect(find.textContaining('不再属于重复媒体'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const Key('media-management-duplicate-delete-confirm-button-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(adapter.hitCount('DELETE', '/media/1'), 1);
    expect(
      find.byKey(const Key('media-management-duplicate-group-1')),
      findsNothing,
    );
    expect(find.text('共 0 组'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('shows and opens collections for duplicate PornBox media', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/duplicates',
      body: _page(total: 1, items: [_duplicateVideoGroupJson()]),
    );
    int? openedCollectionId;
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
      onOpenVideoCollectionDetail: (collectionId) {
        openedCollectionId = collectionId;
      },
    );

    await tester.tap(find.byKey(const Key('media-management-tab-duplicates')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('media-management-duplicate-group-1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('video-collection-chip-3')), findsOneWidget);
    expect(find.text('系列 A'), findsOneWidget);
    expect(find.text('稍后再看'), findsOneWidget);
    expect(find.text('所属合集'), findsNothing);
    await tester.tap(find.byKey(const Key('video-collection-chip-8')));
    expect(openedCollectionId, 8);
  });

  testWidgets('deletes an invalid media item directly', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/invalid',
      body: _page(total: 1, items: [_invalidMediaJson(1)]),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
      switchToMaintenance: true,
    );

    expect(find.byKey(const Key('invalid-media-delete-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('invalid-media-delete-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('invalid-media-delete-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('invalid-media-delete-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(adapter.hitCount('DELETE', '/media/1'), 1);
    expect(find.byKey(const Key('invalid-media-row-1')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('batch deletes selected invalid media', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media/invalid',
      body: _page(
        total: 2,
        items: [_invalidMediaJson(1), _invalidMediaJson(2)],
      ),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    adapter.enqueueJson(method: 'DELETE', path: '/media/2', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
      switchToMaintenance: true,
    );

    await tester.tap(find.byKey(const Key('invalid-media-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invalid-media-row-2')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('invalid-media-selection-count')),
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

  testWidgets('deletes a media item from its card', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(total: 1, items: [_duplicateMediaItemJson(1)]),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(find.byKey(const Key('media-management-delete-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('media-management-delete-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('media-management-delete-dialog-1')),
      findsOneWidget,
    );
    expect(find.text('共 1 条 · 已选 1 项'), findsNothing);
    await tester.tap(
      find.byKey(const Key('media-management-delete-confirm-1')),
    );
    await tester.pumpAndSettle();

    expect(adapter.hitCount('DELETE', '/media/1'), 1);
    expect(find.byKey(const Key('media-management-row-1')), findsNothing);
    expect(find.text('共 0 条'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('deleting a PornBox media syncs the deleted video event', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [_duplicateMediaItemJson(1, kind: 'video', videoItemId: 101)],
      ),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    final events = _watchVideoMutationEvents(tester);
    await tester.tap(find.byKey(const Key('media-management-delete-1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-management-delete-confirm-1')),
    );
    await tester.pumpAndSettle();

    expect(events, hasLength(1));
    expect(events.single.kind, VideoMutationKind.deleted);
    expect(events.single.videoId, 101);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('batch deleting only broadcasts PornBox members', (tester) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 2,
        items: [
          _duplicateMediaItemJson(1, kind: 'video', videoItemId: 101),
          _duplicateMediaItemJson(2),
        ],
      ),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    adapter.enqueueJson(method: 'DELETE', path: '/media/2', statusCode: 204);
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    final events = _watchVideoMutationEvents(tester);
    await tester.tap(
      find.byKey(const Key('media-management-enter-selection-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-row-2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-management-batch-delete-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-management-batch-delete-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(adapter.hitCount('DELETE', '/media/1'), 1);
    expect(adapter.hitCount('DELETE', '/media/2'), 1);
    expect(events, hasLength(1));
    expect(events.single.kind, VideoMutationKind.deleted);
    expect(events.single.videoId, 101);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('batch delete keeps partial failures visible until closed', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 2,
        items: [_duplicateMediaItemJson(1), _duplicateMediaItemJson(2)],
      ),
    );
    adapter.enqueueJson(method: 'DELETE', path: '/media/1', statusCode: 204);
    adapter.enqueueJson(
      method: 'DELETE',
      path: '/media/2',
      statusCode: 500,
      body: <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'delete_failed',
          'message': '删除失败',
        },
      },
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [_duplicateMediaItemJson(2)],
      ),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(
      find.byKey(const Key('media-management-enter-selection-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-row-2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-management-batch-delete-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-management-batch-delete-confirm-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('成功 1 个，失败 1 个'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-progress-close-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 项失败'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('retries a terminal thumbnail from its media card', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [
          _duplicateMediaItemJson(1, thumbnailGenerationState: 'terminal'),
        ],
      ),
    );
    adapter.enqueueJson(
      method: 'POST',
      path: '/media/thumbnail-generation/reset',
      body: <String, dynamic>{'reset_count': 1},
    );
    adapter.enqueueJson(method: 'GET', path: '/media', body: _emptyPage());
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(
      find.byKey(const Key('media-management-retry-thumbnails-1')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('media-management-retry-thumbnails-1')),
    );
    await tester.pumpAndSettle();

    final resetRequest = adapter.requests.singleWhere(
      (request) =>
          request.method == 'POST' &&
          request.path == '/media/thumbnail-generation/reset',
    );
    expect(resetRequest.body, <String, dynamic>{
      'media_ids': <int>[1],
      'force': false,
    });
    expect(find.byKey(const Key('media-management-row-1')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'submits a provider-neutral media transfer from the batch toolbar',
    (tester) async {
      adapter.enqueueJson(
        method: 'GET',
        path: '/media',
        body: _page(total: 1, items: [_duplicateMediaItemJson(1)]),
      );
      adapter.enqueueJson(
        method: 'POST',
        path: '/media-transfers/candidates',
        body: <String, dynamic>{
          'source_library': <String, dynamic>{'id': 1, 'name': '媒体库 A'},
          'targets': <Map<String, dynamic>>[
            <String, dynamic>{'id': 9, 'name': '媒体库 B'},
          ],
        },
      );
      adapter.enqueueJson(
        method: 'POST',
        path: '/media-transfers',
        statusCode: 202,
        body: <String, dynamic>{
          'task_run_id': 88,
          'task_key': 'media_storage_transfer',
          'state': 'pending',
        },
      );
      await _pumpPage(
        tester,
        sessionStore: sessionStore,
        mediaApi: mediaApi,
        apiClient: apiClient,
      );

      await tester.tap(
        find.byKey(const Key('media-management-enter-selection-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('media-management-row-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('media-management-batch-transfer-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('media-management-transfer-dialog')),
        findsOneWidget,
      );
      expect(find.text('媒体库 B'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('media-management-transfer-confirm-button')),
      );
      await tester.pumpAndSettle();

      final requests = adapter.requests
          .where((request) => request.method == 'POST')
          .toList(growable: false);
      expect(requests[0].path, '/media-transfers/candidates');
      expect(requests[0].body, <String, dynamic>{
        'media_ids': <int>[1],
      });
      expect(requests[1].path, '/media-transfers');
      expect(requests[1].body, <String, dynamic>{
        'media_ids': <int>[1],
        'target_library_id': 9,
      });
      expect(
        find.byKey(const Key('media-management-batch-transfer-button')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('submits a single-item transfer from the row transfer icon', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(total: 1, items: [_duplicateMediaItemJson(1)]),
    );
    adapter.enqueueJson(
      method: 'POST',
      path: '/media-transfers/candidates',
      body: <String, dynamic>{
        'source_library': <String, dynamic>{'id': 1, 'name': '媒体库 A'},
        'targets': <Map<String, dynamic>>[
          <String, dynamic>{'id': 9, 'name': '媒体库 B'},
        ],
      },
    );
    adapter.enqueueJson(
      method: 'POST',
      path: '/media-transfers',
      statusCode: 202,
      body: <String, dynamic>{
        'task_run_id': 88,
        'task_key': 'media_storage_transfer',
        'state': 'pending',
      },
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(find.byKey(const Key('media-management-transfer-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('media-management-transfer-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('media-management-transfer-confirm-button')),
    );
    await tester.pumpAndSettle();

    final requests = adapter.requests
        .where((request) => request.method == 'POST')
        .toList(growable: false);
    expect(requests[0].body, <String, dynamic>{
      'media_ids': <int>[1],
    });
    expect(requests[1].body, <String, dynamic>{
      'media_ids': <int>[1],
      'target_library_id': 9,
    });
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('retries selected terminal thumbnails from the filtered list', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [
          _duplicateMediaItemJson(1, thumbnailGenerationState: 'terminal'),
        ],
      ),
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [
          _duplicateMediaItemJson(1, thumbnailGenerationState: 'terminal'),
        ],
      ),
    );
    adapter.enqueueJson(
      method: 'POST',
      path: '/media/thumbnail-generation/reset',
      body: <String, dynamic>{'reset_count': 1},
    );
    adapter.enqueueJson(method: 'GET', path: '/media', body: _emptyPage());
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(
      find.byKey(const Key('media-management-batch-reset-thumbnails-button')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('media-management-filter-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-thumbnail-generation-filter-terminal')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-filter-trigger')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('media-management-enter-selection-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-management-batch-reset-thumbnails-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('media-management-batch-reset-thumbnails-dialog')),
      findsOneWidget,
    );
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
      'force': false,
    });
    expect(find.byKey(const Key('media-management-row-1')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('regenerates selected succeeded thumbnails in force mode', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [
          _duplicateMediaItemJson(1, thumbnailGenerationState: 'succeeded'),
        ],
      ),
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [
          _duplicateMediaItemJson(1, thumbnailGenerationState: 'succeeded'),
        ],
      ),
    );
    adapter.enqueueJson(
      method: 'POST',
      path: '/media/thumbnail-generation/reset',
      body: <String, dynamic>{'reset_count': 1},
    );
    adapter.enqueueJson(method: 'GET', path: '/media', body: _emptyPage());
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(find.byKey(const Key('media-management-filter-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('media-thumbnail-generation-filter-succeeded')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-filter-trigger')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('media-management-enter-selection-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('media-management-row-1')));
    await tester.pumpAndSettle();

    expect(find.text('重新生成缩略图（1）'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('media-management-batch-reset-thumbnails-button')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('将删除已选 1 项现有的缩略图'), findsOneWidget);
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
      'force': true,
    });
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'regenerates a succeeded thumbnail from its media card after confirmation',
    (tester) async {
      adapter.enqueueJson(
        method: 'GET',
        path: '/media',
        body: _page(
          total: 1,
          items: [
            _duplicateMediaItemJson(1, thumbnailGenerationState: 'succeeded'),
          ],
        ),
      );
      adapter.enqueueJson(
        method: 'POST',
        path: '/media/thumbnail-generation/reset',
        body: <String, dynamic>{'reset_count': 1},
      );
      adapter.enqueueJson(method: 'GET', path: '/media', body: _emptyPage());
      await _pumpPage(
        tester,
        sessionStore: sessionStore,
        mediaApi: mediaApi,
        apiClient: apiClient,
      );

      await tester.tap(
        find.byKey(const Key('media-management-retry-thumbnails-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const Key('media-management-single-regenerate-thumbnails-dialog'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const Key(
            'media-management-single-regenerate-thumbnails-confirm-button',
          ),
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
        'force': true,
      });
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('enters selection mode from the header button and toggles rows', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(total: 1, items: [_duplicateMediaItemJson(1)]),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    expect(
      find.byKey(const Key('media-management-enter-selection-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('media-management-select-all-button')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('media-management-enter-selection-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('media-management-select-all-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('media-management-enter-selection-button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('media-management-refresh-button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('media-management-batch-delete-button')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('media-management-row-1')));
    await tester.pumpAndSettle();
    expect(find.text('共 1 条 · 已选 1 项'), findsOneWidget);
    expect(
      find.byKey(const Key('media-management-batch-delete-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('media-management-exit-selection-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('共 1 条'), findsOneWidget);
    expect(
      find.byKey(const Key('media-management-enter-selection-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('media-management-batch-delete-button')),
      findsNothing,
    );
  });

  testWidgets('opens the movie actions dialog from a JAV media row', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(total: 1, items: [_duplicateMediaItemJson(1)]),
    );
    String? openedMovieNumber;
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
      onOpenMovieDetail: (movieNumber) => openedMovieNumber = movieNumber,
    );

    await tester.tap(find.byKey(const Key('media-management-row-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('media-row-movie-actions-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('media-row-movie-actions-play')),
      findsOneWidget,
    );
    expect(find.text('ABC-1'), findsWidgets);
    expect(find.text('共 1 条 · 已选 1 项'), findsNothing);

    await tester.tap(
      find.byKey(const Key('media-row-movie-actions-open-detail')),
    );
    await tester.pumpAndSettle();

    expect(openedMovieNumber, 'ABC-1');
    expect(
      find.byKey(const Key('media-row-movie-actions-dialog')),
      findsNothing,
    );
    expect(find.text('共 1 条 · 已选 1 项'), findsNothing);
  });

  testWidgets('opens the video actions dialog from a PornBox media row', (
    tester,
  ) async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/media',
      body: _page(
        total: 1,
        items: [
          _duplicateMediaItemJson(
            1,
            kind: 'video',
            videoItemId: 101,
            collections: <Map<String, dynamic>>[
              <String, dynamic>{'id': 3, 'name': '系列 A'},
            ],
          ),
        ],
      ),
    );
    await _pumpPage(
      tester,
      sessionStore: sessionStore,
      mediaApi: mediaApi,
      apiClient: apiClient,
    );

    await tester.tap(find.byKey(const Key('media-management-row-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('desktop-video-actions-dialog')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('desktop-video-action-play')), findsOneWidget);
    expect(
      find.byKey(const Key('desktop-video-action-thumbnails')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('desktop-video-action-add-to-collection')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('desktop-video-action-delete')), findsNothing);
    expect(find.byKey(const Key('video-collection-chip-3')), findsOneWidget);
    expect(find.text('共 1 条 · 已选 1 项'), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required SessionStore sessionStore,
  required MediaApi mediaApi,
  required ApiClient apiClient,
  bool switchToMaintenance = false,
  void Function(int collectionId)? onOpenVideoCollectionDetail,
  void Function(String movieNumber)? onOpenMovieDetail,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final needsInjectedContent =
      onOpenVideoCollectionDetail != null || onOpenMovieDetail != null;
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
        home: OKToast(
          child: Scaffold(
            body: !needsInjectedContent
                ? const DesktopMediaManagementPage()
                : MediaManagementContent(
                    keyPrefix: 'media-management',
                    rootKey: const Key('desktop-media-management-page'),
                    onOpenMovieDetail: (_, movieNumber) =>
                        onOpenMovieDetail?.call(movieNumber),
                    onOpenVideoCollectionDetail: (_, collectionId) =>
                        onOpenVideoCollectionDetail?.call(collectionId),
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (switchToMaintenance) {
    await tester.tap(find.byKey(const Key('media-management-tab-maintenance')));
    await tester.pumpAndSettle();
  }
}

List<VideoMutationChange> _watchVideoMutationEvents(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DesktopMediaManagementPage)),
  );
  final events = <VideoMutationChange>[];
  container.listen(videoMutationEventsProvider, (_, next) {
    final change = next.value;
    if (change != null) events.add(change);
  });
  return events;
}

class _EmptyMediaLibrariesApi extends MediaLibrariesApi {
  const _EmptyMediaLibrariesApi({required super.apiClient});

  @override
  Future<List<MediaLibraryDto>> getLibraries() async =>
      const <MediaLibraryDto>[];
}

Map<String, dynamic> _emptyPage() => _page(total: 0, items: const []);

Map<String, dynamic> _page({required int total, required List items}) {
  return <String, dynamic>{
    'items': items,
    'page': 1,
    'page_size': 20,
    'total': total,
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

Map<String, dynamic> _duplicateGroupJson() {
  return <String, dynamic>{
    'kind': 'jav',
    'media_count': 2,
    'media_items': [_duplicateMediaItemJson(1), _duplicateMediaItemJson(2)],
  };
}

Map<String, dynamic> _duplicateVideoGroupJson() {
  return <String, dynamic>{
    'kind': 'video',
    'media_count': 2,
    'media_items': [
      _duplicateMediaItemJson(
        1,
        kind: 'video',
        videoItemId: 101,
        collections: <Map<String, dynamic>>[
          <String, dynamic>{'id': 3, 'name': '系列 A'},
          <String, dynamic>{'id': 8, 'name': '稍后再看'},
        ],
      ),
      _duplicateMediaItemJson(2, kind: 'video', videoItemId: 102),
    ],
  };
}

Map<String, dynamic> _duplicateMediaItemJson(
  int id, {
  String kind = 'jav',
  int? videoItemId,
  List<Map<String, dynamic>> collections = const <Map<String, dynamic>>[],
  String thumbnailGenerationState = 'succeeded',
}) {
  return <String, dynamic>{
    'id': id,
    'kind': kind,
    'movie_number': kind == 'jav' ? 'ABC-$id' : null,
    'video_item_id': videoItemId,
    'title': 'Movie $id',
    'cover_image': null,
    'thin_cover_image': null,
    'library_id': 1,
    'library_name': 'Main Library',
    'file_name': 'abc-$id.mp4',
    'file_size_bytes': 1024,
    'duration_seconds': 60,
    'resolution': '1920x1080',
    'valid': true,
    'thumbnail_generation_state': thumbnailGenerationState,
    'thumbnail_last_error_code': null,
    'heat': 100,
    'collections': collections,
    'created_at': '2026-05-13T12:00:00Z',
    'updated_at': '2026-05-13T12:00:00Z',
  };
}
