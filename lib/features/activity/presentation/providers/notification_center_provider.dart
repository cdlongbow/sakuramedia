import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/data/activity_bootstrap_dto.dart';
import 'package:sakuramedia/features/activity/data/activity_notification_dto.dart';
import 'package:sakuramedia/features/activity/data/activity_stream_event.dart';
import 'package:sakuramedia/features/activity/presentation/activity_filter_state.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/features/activity/presentation/providers/notification_center_state.dart';
import 'package:sakuramedia/features/shared/presentation/providers/sse_channel.dart';

part 'notification_center_provider.g.dart';

/// 全局常驻通知中心。会话登录后自动 bootstrap 并连接 SSE，登出时断流清空。
@Riverpod(keepAlive: true)
class NotificationCenter extends _$NotificationCenter {
  static const int _pageSize = 20;
  static const Duration _longDisconnectThreshold = Duration(minutes: 2);
  static const Duration _pollingInterval = Duration(seconds: 30);
  static const Duration _readDebounceDelay = Duration(milliseconds: 400);

  SessionStore? _sessionStore;
  bool _lastHasSession = false;
  /// SSE 连接状态机：重连退避 / unsupported 轮询兜底 / 长断线补拉 / 微任务
  /// 合批全部由它承担，本 provider 只负责「事件怎么改状态」。
  SseChannel<ActivityStreamEvent>? _channel;
  int _lastEventId = 0;
  int _nextPage = 1;
  int _refreshRequestId = 0;
  int _lifecycleGeneration = 0;
  final Set<int> _pendingReadIds = <int>{};
  final Set<int> _inFlightReadIds = <int>{};
  Timer? _readDebounce;

  @override
  NotificationCenterState build() {
    final sessionStore = ref.watch(sessionStoreProvider);
    _sessionStore = sessionStore;
    _lastHasSession = sessionStore.hasSession;
    sessionStore.addListener(_handleSessionChanged);
    ref.onDispose(() {
      sessionStore.removeListener(_handleSessionChanged);
      _readDebounce?.cancel();
      unawaited(_shutdownChannel());
    });
    if (_lastHasSession) {
      scheduleMicrotask(initialize);
    }
    return NotificationCenterState.initial;
  }

  void _handleSessionChanged() {
    if (!ref.mounted) {
      return;
    }
    final hasSession = _sessionStore?.hasSession ?? false;
    if (hasSession == _lastHasSession) {
      return;
    }
    _lastHasSession = hasSession;
    if (hasSession) {
      unawaited(initialize());
    } else {
      _teardown();
    }
  }

  Future<void> initialize() async {
    if (!ref.mounted || state.initialized || state.isInitialLoading) {
      return;
    }
    await reloadAll();
  }

  Future<void> reloadAll() async {
    final generation = ++_lifecycleGeneration;
    _refreshRequestId += 1;
    // 先同步落 busy，避免 build 安排的自动 initialize 与页面显式 initialize
    // 在第一个 await 处交错，导致后发请求把先发调用提前判 stale。
    state = state.copyWith(
      isInitialLoading: true,
      initialErrorMessage: null,
      refreshErrorMessage: null,
      connectionState: NotificationConnectionState.connecting,
      connectionMessage: '正在同步通知',
    );
    await _shutdownChannel();
    if (!ref.mounted || generation != _lifecycleGeneration) {
      return;
    }
    try {
      final bootstrap = await _loadBootstrapState();
      if (!ref.mounted || generation != _lifecycleGeneration) {
        return;
      }
      _applyBootstrapState(bootstrap);
      state = state.copyWith(
        initialized: true,
        isInitialLoading: false,
        initialErrorMessage: null,
      );
      await _startChannel(generation: generation);
    } catch (error) {
      if (!ref.mounted || generation != _lifecycleGeneration) {
        return;
      }
      state = state.copyWith(
        isInitialLoading: false,
        initialErrorMessage: apiErrorMessage(error, fallback: '通知加载失败，请稍后重试'),
        connectionState: NotificationConnectionState.reconnecting,
        connectionMessage: null,
      );
    }
  }

  Future<void> applyNotificationFilter(
    ActivityNotificationFilterState next,
  ) async {
    if (state.filter == next) {
      return;
    }
    state = state.copyWith(filter: next);
    await refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    final requestId = ++_refreshRequestId;
    state = state.copyWith(
      isRefreshing: true,
      refreshErrorMessage: null,
      loadMoreErrorMessage: null,
    );
    try {
      final response = await ref
          .read(activityApiProvider)
          .getNotifications(
            page: 1,
            pageSize: _pageSize,
            category: state.filter.category,
          );
      if (!ref.mounted || requestId != _refreshRequestId) {
        return;
      }
      final notifications = _sortNotifications(response.items);
      _nextPage = response.page + 1;
      state = state.copyWith(
        notifications: notifications,
        hasMore: notifications.length < response.total,
        loadMoreErrorMessage: null,
        refreshErrorMessage: null,
      );
    } catch (error) {
      if (!ref.mounted || requestId != _refreshRequestId) {
        return;
      }
      state = state.copyWith(
        refreshErrorMessage: apiErrorMessage(error, fallback: '通知筛选刷新失败，请重试'),
      );
    } finally {
      if (ref.mounted && requestId == _refreshRequestId) {
        state = state.copyWith(isRefreshing: false);
      }
    }
  }

  Future<void> loadMoreNotifications() async {
    if (state.isLoadingMore || state.isRefreshing || !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, loadMoreErrorMessage: null);
    try {
      final response = await ref
          .read(activityApiProvider)
          .getNotifications(
            page: _nextPage,
            pageSize: _pageSize,
            category: state.filter.category,
          );
      if (!ref.mounted) {
        return;
      }
      final existingIds = state.notifications.map((item) => item.id).toSet();
      final notifications = <ActivityNotificationDto>[
        ...state.notifications,
        ...response.items.where((item) => existingIds.add(item.id)),
      ];
      _nextPage = response.page + 1;
      state = state.copyWith(
        notifications: notifications,
        hasMore: notifications.length < response.total,
        loadMoreErrorMessage: null,
      );
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          loadMoreErrorMessage: apiErrorMessage(
            error,
            fallback: '加载更多通知失败，请点击重试',
          ),
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  void onNotificationDisplayed(int id) {
    final current = _findNotification(state.notifications, id);
    if (current == null ||
        current.isRead ||
        _inFlightReadIds.contains(id) ||
        _pendingReadIds.contains(id)) {
      return;
    }
    _pendingReadIds.add(id);
    _readDebounce?.cancel();
    _readDebounce = Timer(_readDebounceDelay, _flushPendingReads);
  }

  Future<void> _flushPendingReads() async {
    if (!ref.mounted || _pendingReadIds.isEmpty) {
      return;
    }
    final batch = _pendingReadIds.toList(growable: false);
    _pendingReadIds.clear();
    _inFlightReadIds.addAll(batch);
    state = state.copyWith(
      notifications: _setLocalRead(state.notifications, batch, isRead: true),
    );

    try {
      final result = await ref
          .read(activityApiProvider)
          .markNotificationsRead(batch);
      if (ref.mounted) {
        state = state.copyWith(unreadCount: result.unreadCount);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          notifications: _setLocalRead(
            state.notifications,
            batch,
            isRead: false,
          ),
        );
      }
    } finally {
      _inFlightReadIds.removeAll(batch);
    }
  }

  Future<void> markAllRead() async {
    if (!ref.mounted || state.isMarkingAllRead) {
      return;
    }
    _readDebounce?.cancel();
    _pendingReadIds.clear();
    final previousNotifications = state.notifications;
    final previousUnread = state.unreadCount;
    state = state.copyWith(
      isMarkingAllRead: true,
      notifications: <ActivityNotificationDto>[
        for (final item in state.notifications)
          item.isRead ? item : item.copyWith(isRead: true),
      ],
      unreadCount: 0,
    );

    try {
      final result =
          await ref.read(activityApiProvider).markAllNotificationsRead();
      if (ref.mounted) {
        state = state.copyWith(unreadCount: result.unreadCount);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          notifications: previousNotifications,
          unreadCount: previousUnread,
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isMarkingAllRead: false);
      }
    }
  }

  void _teardown() {
    _lifecycleGeneration += 1;
    _refreshRequestId += 1;
    _readDebounce?.cancel();
    unawaited(_shutdownChannel());
    _pendingReadIds.clear();
    _inFlightReadIds.clear();
    _lastEventId = 0;
    _nextPage = 1;
    state = NotificationCenterState.initial;
  }

  Future<ActivityBootstrapDto> _loadBootstrapState() {
    return ref
        .read(activityApiProvider)
        .getBootstrap(notificationCategory: state.filter.category);
  }

  void _applyBootstrapState(ActivityBootstrapDto response) {
    final notifications = _sortNotifications(response.notifications.items);
    _lastEventId = response.latestEventId;
    _nextPage = response.notifications.page + 1;
    state = state.copyWith(
      notifications: notifications,
      unreadCount: response.unreadCount,
      hasMore: notifications.length < response.notifications.total,
      loadMoreErrorMessage: null,
      refreshErrorMessage: null,
    );
  }

  Future<void> _shutdownChannel() async {
    final channel = _channel;
    _channel = null;
    await channel?.shutdown();
  }

  /// 建连。重连退避（[kActivityBackoff]）、unsupported→30s 轮询兜底、断线
  /// 超过 2 分钟先补拉、微任务合批——全部是 [SseChannel] 的既有行为，这里只
  /// 提供「怎么连」「状态怎么映射到 UI」「事件怎么改 state」三个回调。
  Future<void> _startChannel({required int generation}) async {
    await _shutdownChannel();
    if (!ref.mounted || generation != _lifecycleGeneration) {
      return;
    }
    final channel = SseChannel<ActivityStreamEvent>(
      // afterEventId 由本 provider 自持的 _lastEventId 决定（连流那一刻才读，
      // 重连时自然带上断线期间已消费到的最大事件 id）。
      connect:
          ({String? afterEventId}) => ref
              .read(activityApiProvider)
              .streamEvents(afterEventId: _lastEventId),
      mergeMode: SseMergeMode.microtask,
      pollingInterval: _pollingInterval,
      longDisconnectThreshold: _longDisconnectThreshold,
      onStateChanged:
          (next) => _applyChannelState(next, generation: generation),
      onPollingTick:
          () => unawaited(_refreshFromBootstrap(generation: generation)),
      onLongDisconnectRecover:
          () => _refreshFromBootstrap(generation: generation),
    );
    _channel = channel;
    await channel.start(
      // microtask 合批模式下事件走 onBatch；onEvent 只是模式改变时的等价兜底。
      onEvent:
          (event) => _applyStreamEvents(<ActivityStreamEvent>[
            event,
          ], generation: generation),
      onBatch: (events) => _applyStreamEvents(events, generation: generation),
    );
  }

  void _applyChannelState(
    SseChannelState next, {
    required int generation,
  }) {
    if (!ref.mounted || generation != _lifecycleGeneration) {
      return;
    }
    switch (next) {
      // idle 只在 shutdown 时出现，连接文案由 _teardown / reloadAll 自己写。
      case SseChannelState.idle:
        return;
      case SseChannelState.connecting:
        state = state.copyWith(
          connectionState: NotificationConnectionState.connecting,
          connectionMessage: '正在连接实时通知',
        );
      case SseChannelState.live:
        state = state.copyWith(
          connectionState: NotificationConnectionState.live,
          connectionMessage: '实时连接中',
        );
      case SseChannelState.reconnecting:
        state = state.copyWith(
          connectionState: NotificationConnectionState.reconnecting,
          connectionMessage: '实时连接已断开，正在重连',
        );
      case SseChannelState.polling:
        state = state.copyWith(
          connectionState: NotificationConnectionState.polling,
          connectionMessage: '当前浏览器不支持实时连接，已切换为 30 秒轮询',
        );
      // 通知中心配了 pollingInterval，不会走「放弃订阅」这一支。
      case SseChannelState.unsupportedAbandoned:
        state = state.copyWith(
          connectionState: NotificationConnectionState.reconnecting,
          connectionMessage: null,
        );
    }
  }

  /// 轮询 tick 与长断线补拉共用：重新 bootstrap 一次覆盖本地快照。
  Future<void> _refreshFromBootstrap({required int generation}) async {
    try {
      final bootstrap = await _loadBootstrapState();
      if (ref.mounted && generation == _lifecycleGeneration) {
        _applyBootstrapState(bootstrap);
      }
    } catch (_) {}
  }

  void _applyStreamEvents(
    List<ActivityStreamEvent> events, {
    required int generation,
  }) {
    if (!ref.mounted ||
        generation != _lifecycleGeneration ||
        events.isEmpty) {
      return;
    }
    for (final event in events) {
      if (event.id != null && event.id! > _lastEventId) {
        _lastEventId = event.id!;
      }
    }
    var next = state;
    var changed = false;

    for (final event in events) {
      if (event.isHeartbeat) {
        const message = '实时连接中';
        if (next.connectionState != NotificationConnectionState.live ||
            next.connectionMessage != message) {
          next = next.copyWith(
            connectionState: NotificationConnectionState.live,
            connectionMessage: message,
          );
          changed = true;
        }
      } else if (event.isNotificationCreated && event.notification != null) {
        next = _applyNotificationSnapshot(
          next,
          event.notification!,
          insertAtFrontIfMissing: true,
        );
        changed = true;
      } else if (event.isNotificationUpdated && event.notification != null) {
        next = _applyNotificationSnapshot(next, event.notification!);
        changed = true;
      } else if (event.isNotificationsRead) {
        next = next.copyWith(
          notifications: _setLocalRead(
            next.notifications,
            event.notificationIds ?? const <int>[],
            isRead: true,
          ),
          unreadCount: event.unreadCount ?? next.unreadCount,
        );
        changed = true;
      } else if (event.isNotificationsReadAll) {
        next = next.copyWith(
          notifications: <ActivityNotificationDto>[
            for (final item in next.notifications)
              item.isRead ? item : item.copyWith(isRead: true),
          ],
          unreadCount: event.unreadCount ?? 0,
        );
        changed = true;
      }
    }
    if (changed && ref.mounted) {
      state = next;
    }
  }

  NotificationCenterState _applyNotificationSnapshot(
    NotificationCenterState current,
    ActivityNotificationDto notification, {
    bool insertAtFrontIfMissing = false,
  }) {
    final previous = _findNotification(current.notifications, notification.id);
    final wasUnread = previous != null && !previous.isRead;
    final isUnread = !notification.isRead;
    var unreadCount = current.unreadCount;
    if (!wasUnread && isUnread) {
      unreadCount += 1;
    } else if (wasUnread && !isUnread) {
      unreadCount = (unreadCount - 1).clamp(0, 1 << 31);
    }
    return current.copyWith(
      unreadCount: unreadCount,
      notifications: _upsertNotification(
        current.notifications,
        notification,
        insertAtFront: previous == null && insertAtFrontIfMissing,
        filter: current.filter,
      ),
    );
  }

  List<ActivityNotificationDto> _setLocalRead(
    List<ActivityNotificationDto> source,
    Iterable<int> ids, {
    required bool isRead,
  }) {
    final idSet = ids.toSet();
    var changed = false;
    final result = <ActivityNotificationDto>[
      for (final item in source)
        if (idSet.contains(item.id) && item.isRead != isRead)
          (() {
            changed = true;
            return item.copyWith(isRead: isRead);
          })()
        else
          item,
    ];
    return changed ? result : source;
  }

  List<ActivityNotificationDto> _upsertNotification(
    List<ActivityNotificationDto> source,
    ActivityNotificationDto notification, {
    required bool insertAtFront,
    required ActivityNotificationFilterState filter,
  }) {
    final next = List<ActivityNotificationDto>.from(source);
    final index = next.indexWhere((item) => item.id == notification.id);
    final matches =
        filter.category == null || filter.category == notification.category;
    if (!matches) {
      if (index >= 0) {
        next.removeAt(index);
      }
    } else if (index >= 0) {
      next[index] = next[index].mergeFromServer(notification);
    } else if (insertAtFront) {
      next.insert(0, notification);
    } else {
      next.add(notification);
    }
    return _sortNotifications(next);
  }

  ActivityNotificationDto? _findNotification(
    List<ActivityNotificationDto> source,
    int id,
  ) {
    for (final item in source) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<ActivityNotificationDto> _sortNotifications(
    List<ActivityNotificationDto> items,
  ) {
    final sorted = List<ActivityNotificationDto>.from(items);
    sorted.sort((left, right) {
      final leftAt = left.createdAt?.millisecondsSinceEpoch ?? 0;
      final rightAt = right.createdAt?.millisecondsSinceEpoch ?? 0;
      return rightAt.compareTo(leftAt);
    });
    return sorted;
  }

}
