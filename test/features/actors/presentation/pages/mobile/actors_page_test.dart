import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/presentation/pages/mobile/actors_page.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  late TestApiBundle bundle;

  setUp(() async {
    final session = SessionStore.inMemory();
    await session.saveBaseUrl('https://api.example.com');
    bundle = await createTestApiBundle(session);
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/taste-profile',
      body: _emptyTasteProfileJson(),
    );
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
            locale: const Locale('zh'),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
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
    expect(find.byKey(const Key('mobile-actors-search-field')), findsNothing);
    expect(bundle.adapter.hitCount('GET', '/actors'), 1);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 1),
    );
    await tester.tap(find.byKey(const Key('mobile-actors-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-actors-search-field')), findsOneWidget);

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

  testWidgets('移动女优页顶部展示口味推荐条', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/taste-profile',
      body: _tasteProfileJson(),
    );

    await pumpPage(tester);

    expect(find.byKey(const Key('actor-taste-recommendation')), findsOneWidget);
    expect(find.text('常看女优'), findsOneWidget);
    expect(find.text('口味女优'), findsOneWidget);
  });
}

Map<String, dynamic> _actorsJson({int total = 1}) {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      for (var index = 0; index < total; index++)
      <String, dynamic>{
          'id': index + 1,
          'javdb_id': 'javdb-${index + 1}',
          'name': index == 0 ? '演员一号' : '演员${index + 1}',
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

Map<String, dynamic> _emptyTasteProfileJson() {
  return const <String, dynamic>{
    'sample_movie_count': 0,
    'actresses': <dynamic>[],
    'unsubscribed_actresses': <dynamic>[],
    'tags': <dynamic>[],
  };
}

Map<String, dynamic> _tasteProfileJson() {
  return <String, dynamic>{
    'sample_movie_count': 42,
    'actresses': <dynamic>[
      <String, dynamic>{
        'actor': <String, dynamic>{
          'id': 91,
          'javdb_id': 'taste-actor-91',
          'name': '口味女优',
          'alias_name': '',
          'display_name': '口味女优',
          'is_subscribed': false,
        },
        'matched_movie_count': 9,
      },
    ],
    'unsubscribed_actresses': <dynamic>[
      <String, dynamic>{
        'actor': <String, dynamic>{
          'id': 91,
          'javdb_id': 'taste-actor-91',
          'name': '口味女优',
          'alias_name': '',
          'display_name': '口味女优',
          'is_subscribed': false,
        },
        'matched_movie_count': 9,
      },
    ],
    'tags': <dynamic>[],
  };
}
