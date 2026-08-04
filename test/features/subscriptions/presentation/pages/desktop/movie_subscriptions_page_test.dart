import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/data/activity_api.dart';
import 'package:sakuramedia/features/activity/data/activity_event_stream_client.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';
import 'package:sakuramedia/features/subscriptions/data/api/movie_subscriptions_api.dart';
import 'package:sakuramedia/features/subscriptions/presentation/pages/desktop/movie_subscriptions_page.dart';
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
    apiClient = ApiClient(sessionStore: sessionStore);
    adapter = FakeHttpClientAdapter();
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
  });

  tearDown(() {
    apiClient.dispose();
    sessionStore.dispose();
  });

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieSubscriptionsApiProvider.overrideWithValue(
            MovieSubscriptionsApi(apiClient: apiClient),
          ),
          moviesApiProvider.overrideWithValue(MoviesApi(apiClient: apiClient)),
          activityApiProvider.overrideWithValue(
            ActivityApi(
              apiClient: apiClient,
              streamClient: createActivityEventStreamClient(
                apiClient: apiClient,
                sessionStore: sessionStore,
              ),
            ),
          ),
        ],
        child: OKToast(
          child: MaterialApp(
            theme: sakuraDesktopThemeData,
            home: const Scaffold(body: DesktopMovieSubscriptionsPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(DesktopMovieSubscriptionsPage)),
      listen: false,
    );
  }

  void enqueueCounts({
    int missing = 2,
    int exhausted = 3,
    int importFailed = 0,
    int total = 10,
  }) {
    adapter.setFallbackJson(
      method: 'GET',
      path: '/movie-subscriptions/status-counts',
      body: <String, dynamic>{
        'total': total,
        'imported': 5,
        'import_failed': importFailed,
        'downloading': 0,
        'pending': 0,
        'missing': missing,
        'exhausted': exhausted,
        'failed': 0,
      },
    );
  }

  testWidgets('分段签带计数，默认落在「缺资源」并渲染求片进度', (tester) async {
    enqueueCounts();
    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(
          number: 'ABP-123',
          status: 'missing',
          attemptCount: 2,
          deadCount: 1,
        ),
      ]),
    );

    await pumpPage(tester);

    expect(
      find.byKey(const Key('movie-subscriptions-status-tabs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-subscriptions-status-tab-missing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-subscription-row-number-ABP-123')),
      findsOneWidget,
    );
    // 求片进度：这一页存在的理由，别的影片列表给不出。
    expect(
      find.byKey(const Key('movie-subscription-row-attempts-ABP-123')),
      findsOneWidget,
    );
    expect(find.text('已查 2/3 次'), findsOneWidget);
    expect(
      find.byKey(const Key('movie-subscription-row-dead-ABP-123')),
      findsOneWidget,
    );
    expect(find.text('缺资源'), findsWidgets);
  });

  testWidgets('新片展示「持续查询」而不是查询次数', (tester) async {
    enqueueCounts();
    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(number: 'NEW-001', status: 'missing', isFresh: true),
      ]),
    );

    await pumpPage(tester);

    expect(
      find.byKey(const Key('movie-subscription-row-fresh-NEW-001')),
      findsOneWidget,
    );
    expect(find.text('新片 · 持续查询中'), findsOneWidget);
    expect(
      find.byKey(const Key('movie-subscription-row-attempts-NEW-001')),
      findsNothing,
      reason: '新片 attempt_count 恒为 0，展示次数会被误读成「一次都没查过」',
    );
  });

  testWidgets('待办态为空时给正向文案与「查看全部订阅」出口', (tester) async {
    enqueueCounts(missing: 0);
    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(const <Map<String, dynamic>>[]),
    );

    await pumpPage(tester);

    expect(find.text('没有缺资源的订阅'), findsOneWidget);
    expect(
      find.byKey(const Key('movie-subscriptions-empty-see-all-button')),
      findsOneWidget,
    );
  });

  testWidgets('「重置全部」只在「已放弃」签出现', (tester) async {
    enqueueCounts();
    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(number: 'ABP-123', status: 'missing'),
      ]),
    );
    await pumpPage(tester);
    expect(
      find.byKey(const Key('movie-subscriptions-reset-all-exhausted-button')),
      findsNothing,
    );

    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(number: 'OLD-001', status: 'exhausted'),
      ]),
    );
    await tester.tap(
      find.byKey(const Key('movie-subscriptions-status-tab-exhausted')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-subscriptions-reset-all-exhausted-button')),
      findsOneWidget,
    );
    expect(find.text('重置全部（3）'), findsOneWidget);
  });

  testWidgets('进入多选后顶栏原地改写，行内操作按钮收起', (tester) async {
    enqueueCounts();
    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(number: 'ABP-123', status: 'missing'),
        _item(number: 'ABP-124', status: 'missing'),
      ]),
    );
    await pumpPage(tester);

    expect(
      find.byKey(const Key('movie-subscription-row-reset-ABP-123')),
      findsOneWidget,
    );

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-subscriptions-selection-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-subscriptions-list-header')),
      findsNothing,
      reason: '多选是原地改写整条顶栏，不是另起一行',
    );
    expect(
      find.byKey(const Key('movie-subscription-row-reset-ABP-123')),
      findsNothing,
      reason: '多选态下行内操作与批量动作并存会让改动范围不可预期',
    );
    expect(find.text('已选 0 部'), findsOneWidget);

    await tester.tap(find.text('全选（2）'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 部'), findsOneWidget);
    expect(find.text('重置查询（2）'), findsOneWidget);
  });

  testWidgets('导入失败独立成签，行内重置按钮禁用', (tester) async {
    enqueueCounts(importFailed: 3);
    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(number: 'ABP-123', status: 'missing'),
      ]),
    );
    await pumpPage(tester);

    // 待办组里有独立的一签，且角标带上了计数。
    expect(
      find.byKey(const Key('movie-subscriptions-status-tab-import_failed')),
      findsOneWidget,
    );

    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(number: 'GACHI-1151', status: 'import_failed'),
      ]),
    );
    await tester.tap(
      find.byKey(const Key('movie-subscriptions-status-tab-import_failed')),
    );
    await tester.pumpAndSettle();

    expect(find.text('导入失败'), findsWidgets);
    // 文件已在盘上，重新找种子没意义——按钮必须是禁用的。
    // AppIconButton 把 key 透传给内层 InkWell，所以断言落在 InkWell.onTap 上。
    final resetInk = tester.widget<InkWell>(
      find.byKey(const Key('movie-subscription-row-reset-GACHI-1151')),
    );
    expect(resetInk.onTap, isNull);
    // 取消订阅仍然可用。
    final unsubscribeInk = tester.widget<InkWell>(
      find.byKey(const Key('movie-subscription-row-unsubscribe-GACHI-1151')),
    );
    expect(unsubscribeInk.onTap, isNotNull);
  });

  testWidgets('行内取消订阅移除该行并广播', (tester) async {
    enqueueCounts();
    adapter.enqueueJson(
      method: 'GET',
      path: '/movie-subscriptions',
      body: _page(<Map<String, dynamic>>[
        _item(number: 'ABP-123', status: 'missing'),
        _item(number: 'ABP-124', status: 'missing'),
      ]),
    );
    adapter.enqueueJson(
      method: 'DELETE',
      path: '/movies/ABP-123/subscription',
      statusCode: 204,
    );
    final container = await pumpPage(tester);

    final changes = <MovieSubscriptionChange>[];
    container.listen(movieSubscriptionEventsProvider, (_, next) {
      final batch = next.value;
      if (batch != null) changes.addAll(batch);
    });

    await tester.tap(
      find.byKey(const Key('movie-subscription-row-unsubscribe-ABP-123')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-subscription-row-number-ABP-123')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('movie-subscription-row-number-ABP-124')),
      findsOneWidget,
    );
    expect(changes.single.movieNumber, 'ABP-123');
    expect(changes.single.isSubscribed, isFalse);
    expect(find.text('已取消订阅影片'), findsOneWidget);
    // 排掉 oktoast 的 ~2.3s 计时器，否则测试以「Pending timers」失败。
    await tester.pump(const Duration(seconds: 3));
  });
}

Map<String, dynamic> _item({
  required String number,
  required String status,
  int attemptCount = 0,
  int deadCount = 0,
  bool isFresh = false,
}) {
  return <String, dynamic>{
    // 页面测试不打重置请求，id 只需非零占位。
    'movie_id': number.hashCode.abs() % 100000 + 1,
    'movie_number': number,
    'title': 'Title $number',
    'title_zh': '中文 $number',
    'status': status,
    'is_fresh': isFresh,
    'attempt_count': attemptCount,
    'attempt_limit': 3,
    'dead_download_task_count': deadCount,
    'media_count': 0,
  };
}

Map<String, dynamic> _page(List<Map<String, dynamic>> items) {
  return <String, dynamic>{
    'items': items,
    'page': 1,
    'page_size': 20,
    'total': items.length,
  };
}
