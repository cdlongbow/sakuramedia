import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/presentation/providers/notification_center_provider.dart';
import 'package:sakuramedia/features/activity/presentation/providers/notification_center_state.dart';

import '../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore sessionStore;
  late TestApiBundle bundle;
  late ProviderContainer container;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    bundle = await createTestApiBundle(sessionStore);
    container = ProviderContainer(
      overrides: bundle.riverpodOverrides(),
      retry: (_, _) => null,
    );
  });

  tearDown(() {
    container.dispose();
    bundle.dispose();
    sessionStore.dispose();
  });

  test('reloadAll loads notifications and uses polling state', () async {
    _enqueueBootstrap(bundle, notificationId: 5, unreadCount: 2);

    await container.read(notificationCenterProvider.notifier).reloadAll();

    final state = container.read(notificationCenterProvider);
    expect(state.initialized, isTrue);
    expect(state.connectionState, NotificationConnectionState.polling);
    expect(state.notifications.single.id, 5);
    expect(state.unreadCount, 2);
    expect(
      bundle.adapter.requests.where(
        (request) => request.path.contains('/system/events/'),
      ),
      isEmpty,
    );
  });

  test('markAllRead uses notification mutation endpoint', () async {
    _enqueueBootstrap(bundle, notificationId: 5, unreadCount: 1);
    await container.read(notificationCenterProvider.notifier).reloadAll();
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/system/notifications/read-all',
      body: <String, dynamic>{'updated_count': 1, 'unread_count': 0},
    );

    await container.read(notificationCenterProvider.notifier).markAllRead();

    expect(container.read(notificationCenterProvider).unreadCount, 0);
    expect(bundle.adapter.requests.last.path, '/system/notifications/read-all');
  });

  test('poll keeps loaded pages and patches notifications in place', () {
    fakeAsync((async) {
      void settle() {
        async.elapse(Duration.zero);
        async.flushMicrotasks();
      }

      final controller = container.read(notificationCenterProvider.notifier);
      final firstPage = <Map<String, dynamic>>[
        for (var id = 1; id <= 20; id++) _notificationJson(id: id),
      ];
      final secondPage = <Map<String, dynamic>>[
        for (var id = 21; id <= 40; id++) _notificationJson(id: id),
      ];

      _enqueueBootstrapItems(bundle, items: firstPage, total: 40);
      controller.reloadAll();
      settle();
      expect(
        container.read(notificationCenterProvider).notifications,
        hasLength(20),
      );

      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/system/notifications',
        body: <String, dynamic>{
          'items': secondPage,
          'page': 2,
          'page_size': 20,
          'total': 40,
        },
      );
      controller.loadMoreNotifications();
      settle();
      var state = container.read(notificationCenterProvider);
      expect(state.notifications, hasLength(40));
      expect(state.hasMore, isFalse);

      // 轮询首页快照（id 1 标题变化）+ 未读数查询。
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/system/notifications',
        body: <String, dynamic>{
          'items': <Map<String, dynamic>>[
            for (var id = 1; id <= 20; id++)
              _notificationJson(id: id, title: id == 1 ? '更新' : '通知'),
          ],
          'page': 1,
          'page_size': 20,
          'total': 40,
        },
      );
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/system/notifications',
        body: <String, dynamic>{
          'items': const <dynamic>[],
          'page': 1,
          'page_size': 1,
          'total': 0,
        },
      );

      async.elapse(const Duration(seconds: 31));
      settle();

      state = container.read(notificationCenterProvider);
      expect(state.notifications, hasLength(40));
      expect(
        state.notifications.map((item) => item.id).toSet(),
        <int>{for (var id = 1; id <= 40; id++) id},
      );
      expect(state.hasMore, isFalse);
      expect(
        state.notifications.firstWhere((item) => item.id == 1).title,
        '更新',
      );
    });
  });
}

Map<String, dynamic> _notificationJson({required int id, String title = '通知'}) =>
    <String, dynamic>{
      'id': id,
      'category': 'reminder',
      'title': title,
      'content': '内容',
      'is_read': false,
      'created_at': '2026-03-26T09:10:00Z',
      'updated_at': '2026-03-26T09:10:00Z',
    };

void _enqueueBootstrapItems(
  TestApiBundle bundle, {
  required List<Map<String, dynamic>> items,
  required int total,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/activity/bootstrap',
    body: <String, dynamic>{
      'notifications': <String, dynamic>{
        'items': items,
        'page': 1,
        'page_size': 20,
        'total': total,
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
}

void _enqueueBootstrap(
  TestApiBundle bundle, {
  required int notificationId,
  required int unreadCount,
}) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/activity/bootstrap',
    body: <String, dynamic>{
      'notifications': <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': notificationId,
            'category': 'reminder',
            'title': '通知',
            'content': '内容',
            'is_read': false,
            'created_at': '2026-03-26T09:10:00Z',
            'updated_at': '2026-03-26T09:10:00Z',
          },
        ],
        'page': 1,
        'page_size': 20,
        'total': 1,
      },
      'unread_count': unreadCount,
      'active_task_runs': const <dynamic>[],
      'task_runs': <String, dynamic>{
        'items': const <dynamic>[],
        'page': 1,
        'page_size': 20,
        'total': 0,
      },
    },
  );
}
