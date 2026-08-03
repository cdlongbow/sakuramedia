import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/playlists/data/api/playlists_api.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlist_resolution_options_provider.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_api_provider.dart';

import '../../../../support/fake_http_client_adapter.dart';

void main() {
  late SessionStore sessionStore;
  late ApiClient apiClient;
  late FakeHttpClientAdapter adapter;
  late ProviderContainer container;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-04T12:00:00Z'),
    );
    apiClient = ApiClient(sessionStore: sessionStore);
    adapter = FakeHttpClientAdapter();
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        playlistsApiProvider.overrideWithValue(
          PlaylistsApi(apiClient: apiClient),
        ),
      ],
      retry: (_, __) => null,
    );
  });

  tearDown(() {
    container.dispose();
    apiClient.dispose();
    sessionStore.dispose();
  });

  void keepAlive(int playlistId) {
    final subscription = container.listen(
      playlistResolutionOptionsProvider(playlistId),
      (_, __) {},
    );
    addTearDown(subscription.close);
  }

  List<Map<String, dynamic>> _optionsBody() => <Map<String, dynamic>>[
        <String, dynamic>{'resolution': '8K', 'count': 3},
        <String, dynamic>{'resolution': '4K', 'count': 42},
      ];

  test('build returns initial state without fetching (lazy)', () async {
    keepAlive(8);

    final state = container.read(playlistResolutionOptionsProvider(8));
    expect(state.hasLoaded, isFalse);
    expect(state.isLoading, isFalse);
    expect(state.options, isEmpty);
    // 没触发任何请求。
    expect(adapter.requests, isEmpty);
  });

  test('ensureLoaded triggers the first fetch', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/8/resolutions',
      body: _optionsBody(),
    );

    keepAlive(8);
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .ensureLoaded();

    final state = container.read(playlistResolutionOptionsProvider(8));
    expect(state.hasLoaded, isTrue);
    expect(state.options.map((o) => o.resolution), <String>['8K', '4K']);
  });

  test('ensureLoaded is idempotent after first load', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/8/resolutions',
      body: _optionsBody(),
    );

    keepAlive(8);
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .ensureLoaded();
    // 第二次 ensureLoaded 无请求。
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .ensureLoaded();

    expect(adapter.requests, hasLength(1));
  });

  test('refresh re-fetches only when already loaded', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/8/resolutions',
      body: _optionsBody(),
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/8/resolutions',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'resolution': '1080P', 'count': 120},
      ],
    );

    keepAlive(8);
    // 未加载过 → refresh no-op（无请求）。
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .refresh();
    expect(adapter.requests, isEmpty);

    // 首次 ensureLoaded 拉数据。
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .ensureLoaded();
    expect(adapter.requests, hasLength(1));

    // 加载过后 refresh 会重取。
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .refresh();
    expect(adapter.requests, hasLength(2));
    final state = container.read(playlistResolutionOptionsProvider(8));
    expect(state.options.map((o) => o.resolution), <String>['1080P']);
  });

  test('retry re-fetches regardless of load state', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/8/resolutions',
      body: _optionsBody(),
    );

    keepAlive(8);
    // 未加载过也能通过 retry 触发。
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .retry();
    expect(adapter.requests, hasLength(1));
  });

  test('failure keeps existing options + sets errorMessage', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/8/resolutions',
      body: _optionsBody(),
    );
    adapter.enqueueJson(
      method: 'GET',
      path: '/playlists/8/resolutions',
      statusCode: 500,
      body: <String, dynamic>{'detail': 'boom'},
    );

    keepAlive(8);
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .ensureLoaded();
    await container
        .read(playlistResolutionOptionsProvider(8).notifier)
        .refresh();

    final state = container.read(playlistResolutionOptionsProvider(8));
    // 保留旧 options。
    expect(state.options.map((o) => o.resolution), <String>['8K', '4K']);
    expect(state.errorMessage, '分辨率加载失败');
    expect(state.isLoading, isFalse);
  });
}
