import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/presentation/pages/mobile/actors_page.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  late TestApiBundle bundle;

  setUp(() async {
    final session = SessionStore.inMemory();
    await session.saveBaseUrl('https://api.example.com');
    bundle = await createTestApiBundle(session);
  });

  tearDown(() {
    bundle.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 3),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraThemeData,
            home: const Scaffold(body: MobileActorsPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('移动女优页搜索框防抖后带 query 请求，清空后移除 query', (tester) async {
    await pumpPage(tester);
    expect(
      find.byKey(const Key('mobile-actors-search-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-actors-search-field')),
      findsNothing,
    );
    expect(bundle.adapter.hitCount('GET', '/actors'), 1);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 1),
    );
    await tester.tap(find.byKey(const Key('mobile-actors-search-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mobile-actors-search-field')),
      findsOneWidget,
    );

    // 展开后筛选入口原位保留，数量胶囊暂时隐藏，输入框与 icon 共存。
    expect(
      find.byKey(const Key('mobile-actors-filter-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mobile-actors-total')), findsNothing);
    expect(
      find.byKey(const Key('mobile-actors-search-toggle')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('mobile-actors-search-field')),
      '三上',
    );
    await tester.pump();
    expect(bundle.adapter.hitCount('GET', '/actors'), 1);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final searchRequest = bundle.adapter.requests
        .where((request) => request.path == '/actors')
        .last;
    expect(searchRequest.uri.queryParameters['query'], '三上');
    // 搜索开始时默认「已订阅」放宽为全部。
    expect(searchRequest.uri.queryParameters['subscription_status'], 'all');

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 3),
    );
    await tester.tap(find.byKey(const Key('mobile-actors-search-clear')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final clearedRequest = bundle.adapter.requests
        .where((request) => request.path == '/actors')
        .last;
    expect(clearedRequest.uri.queryParameters.containsKey('query'), isFalse);
    expect(clearedRequest.uri.queryParameters['subscription_status'], 'all');
  });
}

Map<String, dynamic> _actorsJson({int total = 1}) {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'javdb_id': 'javdb-1',
        'name': '演员一号',
        'alias_name': '',
        'profile_image': null,
        'is_subscribed': true,
      },
    ],
    'page': 1,
    'page_size': 24,
    'total': total,
  };
}
