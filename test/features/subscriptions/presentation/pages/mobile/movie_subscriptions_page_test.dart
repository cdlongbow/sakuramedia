import 'package:sakuramedia/features/downloads/data/downloads_api.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/subscriptions/data/api/movie_subscriptions_api.dart';
import 'package:sakuramedia/features/subscriptions/presentation/pages/mobile/movie_subscriptions_page.dart';
import 'package:sakuramedia/features/subscriptions/presentation/providers/movie_subscriptions_api_provider.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/fake_http_client_adapter.dart';

void main() {
  late SessionStore sessionStore;
  late ApiClient apiClient;
  late FakeHttpClientAdapter adapter;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
    );
    apiClient = ApiClient(sessionStore: sessionStore);
    adapter = FakeHttpClientAdapter();
    adapter.setFallbackJson(
      method: 'GET',
      path: '/download-tasks',
      body: {'items': [], 'total': 0, 'page': 1, 'page_size': 100},
    );
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
    adapter.setFallbackJson(
      method: 'GET',
      path: '/movie-subscriptions/status-counts',
      body: <String, dynamic>{'total': 1, 'missing': 1},
    );
  });

  tearDown(() {
    apiClient.dispose();
    sessionStore.dispose();
  });

  testWidgets('renders mobile rows with the full action set', (tester) async {
    _enqueuePage(adapter, [_item('ABP-123')]);
    await _pumpPage(tester, sessionStore, apiClient);

    expect(
      find.byKey(const Key('mobile-movie-subscriptions-page')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-subscription-row-number-ABP-123')),
      findsOneWidget,
    );
    // 移动端操作图标不再挤在信息行尾，但动作完整保留。
    expect(
      find.byKey(const Key('movie-subscription-row-magnet-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-subscription-row-unsubscribe')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-subscriptions-filter-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows download task entry when the movie has tasks', (tester) async {
    _enqueuePage(adapter, [_item('ABP-123')]);
    adapter.setFallbackJson(
      method: 'GET',
      path: '/download-tasks',
      body: {
        'items': [
          {'id': 41, 'movie_number': 'ABP-123', 'name': 'ABP-123 task'},
        ],
        'total': 1,
        'page': 1,
        'page_size': 100,
      },
    );
    await _pumpPage(tester, sessionStore, apiClient);

    expect(
      find.byKey(const Key('movie-subscription-row-downloads')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile filter drawer reuses the shared panel and applies sort', (
    tester,
  ) async {
    _enqueuePage(adapter, [_item('ABP-123')]);
    await _pumpPage(tester, sessionStore, apiClient);

    await tester.tap(
      find.byKey(const Key('movie-subscriptions-filter-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('movie-subscriptions-filter-drawer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-subscriptions-filter-sort-field')),
      findsOneWidget,
    );

    _enqueuePage(adapter, [_item('ABP-123')]);
    await tester.tap(
      find.byKey(const Key('movie-subscriptions-filter-sort-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('订阅时间 · 旧到新').last);
    await tester.pumpAndSettle();

    expect(
      _listRequests(adapter).last.uri.queryParameters['sort'],
      'subscribed_at:asc',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile selection uses the bottom bar for batch unsubscribe', (
    tester,
  ) async {
    _enqueuePage(adapter, [_item('ABP-123'), _item('ABP-124')]);
    await _pumpPage(tester, sessionStore, apiClient);

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('movie-subscriptions-selection-header')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('movie-subscriptions-select-all-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('已选 2 部'), findsOneWidget);

    adapter.enqueueJson(
      method: 'POST',
      path: '/movies/unsubscriptions',
      body: <String, dynamic>{
        'requested_count': 2,
        'updated_count': 2,
        'skipped_count': 0,
        'skipped': <dynamic>[],
      },
    );
    _enqueuePage(adapter, [_item('ABP-123'), _item('ABP-124')]);
    await tester.tap(
      find.byKey(const Key('movie-subscriptions-batch-unsubscribe-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消订阅'));
    await tester.pumpAndSettle();

    final request = adapter.requests.singleWhere(
      (r) => r.method == 'POST' && r.path == '/movies/unsubscriptions',
    );
    expect(request.body.toString(), contains('ABP-123'));
    expect(request.body.toString(), contains('ABP-124'));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('batch delete downloads from the bottom bar', (tester) async {
    _enqueuePage(adapter, [_item('ABP-123')]);
    adapter.setFallbackJson(
      method: 'GET',
      path: '/download-tasks',
      body: {
        'items': [
          {'id': 41, 'movie_number': 'ABP-123', 'name': 'ABP-123 task'},
        ],
        'total': 1,
        'page': 1,
        'page_size': 100,
      },
    );
    await _pumpPage(tester, sessionStore, apiClient);

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movie-subscriptions-select-all-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movie-subscriptions-batch-delete-downloads-button')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 个下载任务'), findsOneWidget);

    adapter.enqueueJson(
      method: 'DELETE',
      path: '/download-tasks/41',
      statusCode: 204,
    );
    adapter.setFallbackJson(
      method: 'GET',
      path: '/download-tasks',
      body: {'items': [], 'total': 0, 'page': 1, 'page_size': 100},
    );
    _enqueuePage(adapter, [_item('ABP-123')]);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(adapter.hitCount('DELETE', '/download-tasks/41'), 1);
    await tester.pump(const Duration(seconds: 3));
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  SessionStore sessionStore,
  ApiClient apiClient,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        downloadsApiProvider.overrideWithValue(
          DownloadsApi(apiClient: apiClient),
        ),
        sessionStoreProvider.overrideWithValue(sessionStore),
        movieSubscriptionsApiProvider.overrideWithValue(
          MovieSubscriptionsApi(apiClient: apiClient),
        ),
        moviesApiProvider.overrideWithValue(MoviesApi(apiClient: apiClient)),
      ],
      child: OKToast(
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: const Scaffold(body: MobileMovieSubscriptionsPage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _enqueuePage(
  FakeHttpClientAdapter adapter,
  List<Map<String, dynamic>> items, {
  int page = 1,
  int? total,
}) {
  adapter.enqueueJson(
    method: 'GET',
    path: '/movie-subscriptions',
    body: <String, dynamic>{
      'items': items,
      'page': page,
      'page_size': 20,
      'total': total ?? items.length,
    },
  );
}

Map<String, dynamic> _item(String number) => <String, dynamic>{
  'movie_id': int.parse(number.split('-').last),
  'movie_number': number,
  'title': 'Title $number',
  'status': 'missing',
  'is_fresh': false,
  'attempt_count': 0,
  'attempt_limit': 3,
  'dead_download_task_count': 0,
  'media_count': 0,
};

List<RecordedRequest> _listRequests(FakeHttpClientAdapter adapter) => adapter
    .requests
    .where((request) => request.path == '/movie-subscriptions')
    .toList();
