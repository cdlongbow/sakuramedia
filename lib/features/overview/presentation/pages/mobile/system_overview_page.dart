import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/providers/overview_system_info_provider.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/asset_summary_card.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/service_health_card.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/storage_usage_card.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/watch_trend_card.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';

class MobileSystemOverviewPage extends ConsumerWidget {
  const MobileSystemOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(overviewSystemInfoProvider);
    final notifier = ref.read(overviewSystemInfoProvider.notifier);
    return KeyedSubtree(
      key: const Key('mobile-system-overview-page'),
      child: AppAdaptiveRefreshScrollView(
        onRefresh: notifier.refresh,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AssetSummaryCard(
                  status: state.status,
                  insights: state.insights,
                  pendingIndexCount: pendingIndexCount(state.imageSearchStatus),
                  isLoading: state.isLoadingStatus,
                  errorMessage: state.statusError,
                  onRetry: notifier.loadStatus,
                ),
                SizedBox(height: context.appSpacing.md),
                WatchTrendCard(
                  trend: state.watchTrend,
                  range: state.watchTrendRange,
                  onRangeChanged: notifier.setWatchTrendRange,
                  compactSelector: true,
                  isLoading: state.isLoadingWatchTrend,
                  errorMessage: state.watchTrendError,
                  onRetry: notifier.loadWatchTrend,
                ),
                SizedBox(height: context.appSpacing.md),
                StorageUsageCard(
                  libraries: state.insights?.mediaLibraries,
                  isLoading: state.isLoadingInsights,
                  errorMessage: state.insightsError,
                  onRetry: notifier.loadInsights,
                ),
                SizedBox(height: context.appSpacing.md),
                ServiceHealthCard(
                  imageSearchStatus: state.imageSearchStatus,
                  javdbHealthy: state.javdbHealthy,
                  isLoading: state.isLoadingImageSearchStatus,
                  isTestingExternalDataSources:
                      state.isTestingMetadataProviders,
                  isRebuildingIndex: state.isResettingImageSearch,
                  onTestExternalDataSources: notifier.testExternalDataSources,
                  onRebuildIndex: () => _confirmImageSearchReset(
                    context,
                    notifier,
                    state.imageSearchStatus?.indexSpace.indexedSpaceId,
                    state.imageSearchStatus?.indexSpace.currentSpaceId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImageSearchReset(
    BuildContext context,
    OverviewSystemInfo notifier,
    String? indexedSpaceId,
    String? currentSpaceId,
  ) async {
    final spaceMessage = indexedSpaceId == null
        ? '无法确认历史索引使用的嵌入空间。'
        : '嵌入空间已从「$indexedSpaceId」变更为「${currentSpaceId ?? '未知'}」。';
    final confirmed = await showAppConfirmDialog(
      context,
      title: '重建图搜索索引',
      message: '$spaceMessage 这会清空现有图片索引并重新开始构建，确认继续吗？',
      confirmLabel: '重建索引',
      danger: true,
      dialogKey: const Key('mobile-image-search-reset-confirm-dialog'),
      confirmKey: const Key('mobile-image-search-reset-confirm'),
      cancelKey: const Key('mobile-image-search-reset-cancel'),
      onConfirm: notifier.resetImageSearch,
      failureFallback: '重建图搜索索引失败',
    );
    if (confirmed && context.mounted) {
      showToast('图搜索索引已开始重建');
    }
  }
}
