import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/activity/presentation/activity_placeholders.dart';
import 'package:sakuramedia/features/activity/data/activity_notification_dto.dart';
import 'package:sakuramedia/features/activity/presentation/activity_filter_state.dart';
import 'package:sakuramedia/features/activity/presentation/providers/notification_center_provider.dart';
import 'package:sakuramedia/features/activity/presentation/notification_card.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_load_more_footer_sliver.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_filter_result_loading_overlay.dart';
import 'package:sakuramedia/widgets/base/feedback/app_filter_update_bar.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';

/// 独立的「通知」消息中心页。列表、分页、筛选和无感已读由全局通知 provider
/// 驱动，卡片被渲染时即上报已读。
class DesktopNotificationsPage extends ConsumerStatefulWidget {
  const DesktopNotificationsPage({super.key});

  @override
  ConsumerState<DesktopNotificationsPage> createState() =>
      _DesktopNotificationsPageState();
}

class _DesktopNotificationsPageState
    extends ConsumerState<DesktopNotificationsPage> {
  static const double _loadMoreTriggerOffset = 300;

  final ScrollController _scrollController = ScrollController();
  Object? _lastAutoLoadSignature;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(notificationCenterProvider.notifier).initialize());
        _maybeAutoLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    _maybeAutoLoadMore();
  }

  /// 只在「已加载条数 / hasMore / 筛选」变化时补视口，避免每次重建（含轮询 tick）
  /// 都触发下一页自动加载。滚动事件仍直接走 [_maybeAutoLoadMore]。
  void _scheduleAutoLoadOnListChange() {
    final state = ref.read(notificationCenterProvider);
    final signature = Object.hash(
      state.notifications.length,
      state.hasMore,
      state.filter,
    );
    if (signature == _lastAutoLoadSignature) {
      return;
    }
    _lastAutoLoadSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeAutoLoadMore();
      }
    });
  }

  void _maybeAutoLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (!_shouldAutoLoadMoreForViewport()) {
      return;
    }
    final state = ref.read(notificationCenterProvider);
    if (state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreErrorMessage == null) {
      unawaited(
        ref.read(notificationCenterProvider.notifier).loadMoreNotifications(),
      );
    }
  }

  bool _shouldAutoLoadMoreForViewport() {
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) {
      return true;
    }
    return position.pixels >= position.maxScrollExtent - _loadMoreTriggerOffset;
  }

  @override
  Widget build(BuildContext context) {
    // 只订阅头部渲染所需的字段：轮询 tick 与已读回执只重建变化的行/页脚，
    // 不重建整页（见 _NotificationsBodySliver / _NotificationsFooterSliver）。
    final header = ref.watch(
      notificationCenterProvider.select((state) {
        return (
          filter: state.filter,
          unreadCount: state.unreadCount,
          isMarkingAllRead: state.isMarkingAllRead,
          filterUpdate: state.filterUpdate,
          hasItems: state.notifications.isNotEmpty,
        );
      }),
    );
    ref.listen(notificationCenterProvider.select((value) => value.filter), (
      previous,
      next,
    ) {
      if (previous != next && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _scheduleAutoLoadOnListChange();
    return AppPageRefreshScope(
      onRefresh: ref
          .read(notificationCenterProvider.notifier)
          .refreshNotifications,
      child: AppFixedHeaderLayout(
        header: _buildHeader(
          context,
          filter: header.filter,
          unreadCount: header.unreadCount,
          isMarkingAllRead: header.isMarkingAllRead,
          filterUpdate: header.filterUpdate,
          hasItems: header.hasItems,
        ),
        child: AppFilterResultLoadingOverlay(
          isLoading: header.filterUpdate.isLoading,
          hasPreviousItems: header.hasItems,
          child: CustomScrollView(
            controller: _scrollController,
            // 收敛视口外预构建，避免卡片「提前已读」。
            cacheExtent: 0,
            slivers: <Widget>[
              const _NotificationsBodySliver(),
              // 通知列表页脚常驻：loading / 失败时显示行，空闲只留上下间距
              // （空列表 + 筛选失败时不占位，与原逻辑一致）。
              PagedLoadMoreFooterSliver(
                topSpacing: PagedFooterSpacing.lg,
                bottomSpacing: PagedFooterSpacing.xl,
                padWhenIdle: true,
                watchFooter: (ref) => ref.watch(
                  notificationCenterProvider.select((state) {
                    if (state.notifications.isEmpty &&
                        state.filterUpdate.hasFailed) {
                      return null;
                    }
                    return (
                      isLoading: state.isLoadingMore,
                      errorMessage: state.loadMoreErrorMessage,
                    );
                  }),
                ),
                onLoadMore: (ref) => unawaited(
                  ref
                      .read(notificationCenterProvider.notifier)
                      .loadMoreNotifications(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {
    required ActivityNotificationFilterState filter,
    required int unreadCount,
    required bool isMarkingAllRead,
    required FilterUpdateState filterUpdate,
    required bool hasItems,
  }) {
    final notifier = ref.read(notificationCenterProvider.notifier);
    return Padding(
      key: const Key('desktop-notifications-page'),
      padding: EdgeInsets.only(bottom: context.appSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: NotificationFilterBar(
                  filter: filter,
                  onFilterChanged: notifier.applyNotificationFilter,
                ),
              ),
              SizedBox(width: context.appSpacing.md),
              AppButton(
                key: const Key('notifications-mark-all-read'),
                label: '全部已读',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                isLoading: isMarkingAllRead,
                onPressed: unreadCount > 0 && !isMarkingAllRead
                    ? notifier.markAllRead
                    : null,
              ),
            ],
          ),
          AppFilterUpdateBar(
            state: filterUpdate,
            hasPreviousItems: hasItems,
            onRetry: notifier.refreshNotifications,
          ),
        ],
      ),
    );
  }
}

/// 桌面通知列表本体：只订阅条目 id 序列与四态。
///
/// 轮询 tick / 已读回执只改变行内数据（序列不变），不重建列表；
/// 各行通过 [_NotificationRowItem] 独立订阅自己的已读态。
class _NotificationsBodySliver extends ConsumerWidget {
  const _NotificationsBodySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(
      notificationCenterProvider.select((state) {
        return (
          ids: state.notifications.map((item) => item.id).join(','),
          isInitialLoading: state.isInitialLoading,
          initialError: state.initialErrorMessage,
          filterFailed: state.filterUpdate.hasFailed,
        );
      }),
    );
    if (body.isInitialLoading && body.ids.isEmpty) {
      // loading 用占位通知渲染真实列表与卡片，由 [AppSkeletonizer] 灰化。
      final placeholders = activityNotificationPlaceholders();
      return AppSkeletonizer.sliver(
        enabled: true,
        child: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final isLast = index == placeholders.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : context.appSpacing.md,
              ),
              child: RepaintBoundary(
                child: NotificationCard(
                  notification: placeholders[index],
                ),
              ),
            );
          }, childCount: placeholders.length),
        ),
      );
    }
    if (body.initialError != null && body.ids.isEmpty) {
      return SliverToBoxAdapter(
        child: _NotificationsErrorState(
          message: body.initialError!,
          onRetry: ref.read(notificationCenterProvider.notifier).reloadAll,
        ),
      );
    }
    if (body.ids.isEmpty) {
      if (body.filterFailed) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '当前筛选下暂无通知'),
      );
    }
    // 条目快照只读不订阅：序列变化时本体重建，快照即新；
    // 行内变化（已读翻转）由各行独立订阅。
    final ids = body.ids.split(',').map(int.parse).toList(growable: false);
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final itemId = ids[index];
        final isLast = index == ids.length - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: isLast ? 0 : context.appSpacing.md,
          ),
          child: RepaintBoundary(
            child: _NotificationRowItem(itemId: itemId),
          ),
        );
      }, childCount: ids.length),
    );
  }
}

/// 桌面通知单行：独立订阅自己的通知对象（已读翻转只重建本行）。
class _NotificationRowItem extends ConsumerWidget {
  const _NotificationRowItem({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      notificationCenterProvider.select(
        (state) => _notificationById(state.notifications, itemId),
      ),
    );
    // 缺席（被删除）时整行 hidden；结构变化会重建列表清掉它。
    if (item == null) return const SizedBox.shrink();
    final notifier = ref.read(notificationCenterProvider.notifier);
    // 卡片被构建（展示）即视为已读，帧后上报避免在 build 中改状态。
    if (!item.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.onNotificationDisplayed(item.id);
      });
    }
    return NotificationCard(notification: item);
  }
}

/// 按 id 取通知快照（行卡独立订阅用）；缺席返回 null，调用方回退占位。
ActivityNotificationDto? _notificationById(
  List<ActivityNotificationDto> notifications,
  int id,
) {
  for (final item in notifications) {
    if (item.id == id) return item;
  }
  return null;
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('desktop-notifications-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppEmptyState(message: message),
        SizedBox(height: context.appSpacing.lg),
        AppButton(label: '重试', onPressed: () => onRetry()),
      ],
    );
  }
}
