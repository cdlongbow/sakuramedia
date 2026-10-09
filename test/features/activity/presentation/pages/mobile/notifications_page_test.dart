import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/presentation/pages/mobile/notifications_page.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets('renders mobile notification snapshot and segments', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
    );
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 101,
              'category': 'reminder',
              'title': '提醒通知',
              'content': '内容',
              'is_read': true,
              'created_at': '2026-08-10T09:00:00Z',
              'updated_at': '2026-08-10T09:00:00Z',
            },
          ],
          'page': 1,
          'page_size': 20,
          'total': 1,
        },
        'unread_count': 0,
        'active_task_runs': const <dynamic>[],
        'task_runs': <String, dynamic>{
          'items': const <dynamic>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const Scaffold(body: MobileNotificationsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-notifications-page')), findsOneWidget);
    expect(find.byKey(const Key('mobile-notifications-segments')), findsOneWidget);
    expect(find.byKey(const Key('mobile-activity-notification-101')), findsOneWidget);
  });

  testWidgets('unread snapshot waits for data before freezing', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
    );
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 101,
              'category': 'reminder',
              'title': '未读提醒',
              'content': '内容',
              'is_read': false,
              'created_at': '2026-08-10T09:00:00Z',
              'updated_at': '2026-08-10T09:00:00Z',
            },
          ],
          'page': 1,
          'page_size': 20,
          'total': 1,
        },
        'unread_count': 1,
        'active_task_runs': const <dynamic>[],
        'task_runs': <String, dynamic>{
          'items': const <dynamic>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
      },
    );
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/system/notifications/read',
      body: <String, dynamic>{'updated_count': 1, 'unread_count': 0},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const Scaffold(body: MobileNotificationsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 页面是 provider 的首个监听者（深链/冷启动）：首帧 initial 状态不能把
    // 空列表固化成快照，数据到达后未读红点必须可见。
    expect(
      find.byKey(const Key('mobile-activity-notification-101-dot')),
      findsOneWidget,
    );
  });
}
