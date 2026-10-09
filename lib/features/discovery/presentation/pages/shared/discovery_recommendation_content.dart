import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/discovery/data/daily_recommendation_movie_dto.dart';
import 'package:sakuramedia/features/discovery/data/hot_actress_release_movie_dto.dart';
import 'package:sakuramedia/features/discovery/data/moment_recommendation_dto.dart';
import 'package:sakuramedia/features/discovery/presentation/moment_recommendation_mapping.dart';
import 'package:sakuramedia/features/discovery/presentation/providers/discovery_recommendation_feeds_provider.dart';
import 'package:sakuramedia/features/moments/presentation/actions/moment_preview_flow.dart';
import 'package:sakuramedia/features/moments/presentation/moment_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/features/movies/presentation/movie_placeholders.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/features/shared/presentation/hooks/paged_scroll_hook.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_load_more_footer_sliver.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_grid.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';

/// 推荐影片列表共享实现（桌面 / 移动双端壳收敛的 content 层）。
///
/// 平台差异全部收在壳参数里：`pageSize`（移动 18 / 桌面 24）、`keyPrefix`、
/// 顶栏下间距（`headerGap`）、背景色、骨架数、`basePath`（消掉旧的
/// `_movieDetailPath(isMobile:)`）与下拉刷新开关；`basePath` 之下影片详情路径
/// 与本列表自身的分页/刷新/错误态逻辑全部在本层。
class DiscoveryMoviesContent extends StatelessWidget {
  const DiscoveryMoviesContent({
    super.key,
    required this.pageSize,
    required this.keyPrefix,
    required this.headerGap,
    required this.backgroundColor,
    required this.placeholderCount,
    required this.basePath,
    this.enablePullToRefresh = false,
  });

  final int pageSize;
  final String keyPrefix;
  final double headerGap;
  final Color backgroundColor;
  final int placeholderCount;
  final String basePath;
  final bool enablePullToRefresh;

  @override
  Widget build(BuildContext context) {
    final provider = dailyRecommendationFeedProvider(pageSize);
    return _DiscoveryMovieListContent<DailyRecommendationMovieDto>(
      keyPrefix: keyPrefix,
      headerGap: headerGap,
      backgroundColor: backgroundColor,
      placeholderCount: placeholderCount,
      basePath: basePath,
      enablePullToRefresh: enablePullToRefresh,
      initialLoadErrorText: '推荐影片加载失败，请稍后重试',
      loadMoreErrorText: '加载更多推荐影片失败，请点击重试',
      emptyMessage: '暂无推荐影片，去搜索看看吧',
      // 中立化 loadMore 状态：翻页 loading/失败只重建独立页脚，不重建网格。
      watch: (ref) => ref.watch(
        provider.select(
          (asyncValue) => asyncValue.whenData(withoutLoadMoreStatus),
        ),
      ),
      loadMore: (ref) => ref.read(provider.notifier).loadMore(),
      reload: (ref) => ref.read(provider.notifier).reload(),
      refresh: (ref) => ref.read(provider.notifier).refresh(),
      movieOf: (item) => item.movie,
      watchLoadMoreFooter: (ref) => ref.watch(
        provider.select((asyncState) {
          final paged = asyncState.value;
          if (paged == null || paged.isEmpty) {
            return (isLoading: false, errorMessage: null, hasItems: false);
          }
          return (
            isLoading: paged.isLoadingMore,
            errorMessage: paged.loadMoreErrorMessage,
            hasItems: true,
          );
        }),
      ),
      readLoadMoreError: (ref) =>
          ref.read(provider).value?.loadMoreErrorMessage,
    );
  }
}

/// 热门新片列表，复用与每日推荐一致的分页和卡片交互。
class HotActressReleasesContent extends StatelessWidget {
  const HotActressReleasesContent({
    super.key,
    required this.pageSize,
    required this.keyPrefix,
    required this.headerGap,
    required this.backgroundColor,
    required this.placeholderCount,
    required this.basePath,
    this.enablePullToRefresh = false,
  });

  final int pageSize;
  final String keyPrefix;
  final double headerGap;
  final Color backgroundColor;
  final int placeholderCount;
  final String basePath;
  final bool enablePullToRefresh;

  @override
  Widget build(BuildContext context) {
    final provider = hotActressReleaseFeedProvider(pageSize);
    return _DiscoveryMovieListContent<HotActressReleaseMovieDto>(
      keyPrefix: keyPrefix,
      headerGap: headerGap,
      backgroundColor: backgroundColor,
      placeholderCount: placeholderCount,
      basePath: basePath,
      enablePullToRefresh: enablePullToRefresh,
      initialLoadErrorText: '热门新片加载失败，请稍后重试',
      loadMoreErrorText: '加载更多热门新片失败，请点击重试',
      emptyMessage: '暂无热门新片，待更多影片积累热度后展示',
      // 中立化 loadMore 状态：翻页 loading/失败只重建独立页脚，不重建网格。
      watch: (ref) => ref.watch(
        provider.select(
          (asyncValue) => asyncValue.whenData(withoutLoadMoreStatus),
        ),
      ),
      loadMore: (ref) => ref.read(provider.notifier).loadMore(),
      reload: (ref) => ref.read(provider.notifier).reload(),
      refresh: (ref) => ref.read(provider.notifier).refresh(),
      movieOf: (item) => item.movie,
      watchLoadMoreFooter: (ref) => ref.watch(
        provider.select((asyncState) {
          final paged = asyncState.value;
          if (paged == null || paged.isEmpty) {
            return (isLoading: false, errorMessage: null, hasItems: false);
          }
          return (
            isLoading: paged.isLoadingMore,
            errorMessage: paged.loadMoreErrorMessage,
            hasItems: true,
          );
        }),
      ),
      readLoadMoreError: (ref) =>
          ref.read(provider).value?.loadMoreErrorMessage,
      useDefaultSubscriptionActions: true,
      secondaryLabelOf: (item) {
        final name = item.hotActressName.trim();
        return name.isEmpty ? null : '热门：$name';
      },
    );
  }
}

class _DiscoveryMovieListContent<T> extends HookConsumerWidget {
  const _DiscoveryMovieListContent({
    required this.keyPrefix,
    required this.headerGap,
    required this.backgroundColor,
    required this.placeholderCount,
    required this.basePath,
    required this.initialLoadErrorText,
    required this.loadMoreErrorText,
    required this.emptyMessage,
    required this.watch,
    required this.watchLoadMoreFooter,
    required this.readLoadMoreError,
    required this.loadMore,
    required this.reload,
    required this.refresh,
    required this.movieOf,
    this.enablePullToRefresh = false,
    this.useDefaultSubscriptionActions = false,
    this.secondaryLabelOf,
  });

  final String keyPrefix;
  final double headerGap;
  final Color backgroundColor;
  final int placeholderCount;
  final String basePath;
  final String initialLoadErrorText;
  final String loadMoreErrorText;
  final String emptyMessage;
  final AsyncValue<PagedListState<T>> Function(WidgetRef ref) watch;

  /// loadMore 状态的窄订阅：页脚用它 watch，只在 loading/失败/条目空否变化时重建。
  final ({bool isLoading, String? errorMessage, bool hasItems}) Function(
    WidgetRef ref,
  )
  watchLoadMoreFooter;

  /// 读 loadMore 失败存续（不订阅）：滚动守卫用它判断失败存续期间不自动重试。
  final String? Function(WidgetRef ref) readLoadMoreError;
  final Future<void> Function(WidgetRef ref) loadMore;
  final Future<void> Function(WidgetRef ref) reload;
  final Future<String?> Function(WidgetRef ref) refresh;
  final MovieListItemDto Function(T item) movieOf;
  final bool useDefaultSubscriptionActions;
  final String? Function(T item)? secondaryLabelOf;
  final bool enablePullToRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = watch(ref);
    final paged = async.value ?? PagedListState<T>();
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        // 对齐旧 PagedLoadController：loadMore 失败存续期间滚动不自动重试，
        // 恢复分页的唯一入口是 footer 的重试按钮。
        // 读独立取值（不订阅，避免翻页状态触发本体重建）。
        if (readLoadMoreError(ref) == null) {
          unawaited(loadMore(ref));
        }
      },
      triggerOffset: 300,
    );

    final sliver = SliverMainAxisGroup(
      key: Key('$keyPrefix-page'),
      slivers: [
        _buildBody(context, ref, async, paged),
        // loadMore 页脚独立订阅：翻页状态翻转只重建它，不重建上面网格。
        PagedLoadMoreFooterSliver(
          watchFooter: (ref) {
            final footer = watchLoadMoreFooter(ref);
            if (!footer.hasItems) {
              return null;
            }
            return (
              isLoading: footer.isLoading,
              errorMessage: footer.errorMessage ?? loadMoreErrorText,
            );
          },
          onLoadMore: (ref) => unawaited(loadMore(ref)),
        ),
      ],
    );

    return AppFixedHeaderLayout(
      header: SizedBox(height: headerGap),
      child: AppPageRefreshScope(
        onRefresh: () => _handleRefresh(context, ref),
        child: enablePullToRefresh
            ? ColoredBox(
                color: backgroundColor,
                child: AppAdaptiveRefreshScrollView(
                  controller: scrollController,
                  onRefresh: () => _handleRefresh(context, ref),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[sliver],
                ),
              )
            : ColoredBox(
                color: backgroundColor,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [sliver],
                ),
              ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final errorMessage = await refresh(ref);
    if (errorMessage != null && context.mounted) {
      showToast('刷新失败');
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<PagedListState<T>> async,
    PagedListState<T> paged,
  ) {
    if (async.hasError) {
      return SliverToBoxAdapter(
        child: DiscoveryRetryEmptyState(
          message: initialLoadErrorText,
          onRetry: () => reload(ref),
        ),
      );
    }
    final secondaryLabels = <String, String>{};
    for (final item in paged.items) {
      final label = secondaryLabelOf?.call(item)?.trim();
      if (label != null && label.isNotEmpty) {
        secondaryLabels[movieOf(item).movieNumber] = label;
      }
    }
    final isLoading = async.isLoading && async.value == null;
    final hoverActions = movieCardHoverFeatureActions(context);
    return AppSkeletonizer.sliver(
      enabled: isLoading,
      child: MovieSummarySliver(
        items: isLoading
            ? movieListItemPlaceholders(count: placeholderCount)
            : paged.items.map(movieOf).toList(growable: false),
        emptyMessage: emptyMessage,
        secondaryLabelForMovie: secondaryLabels.isEmpty
            ? null
            : (movie) => secondaryLabels[movie.movieNumber],
        useDefaultSubscriptionActions: useDefaultSubscriptionActions,
        onMovieTap: (movie) => _openMovieDetail(context, movie.movieNumber),
        onMovieMenuRequest: (movie, globalPosition) =>
            requestMovieCollectionMenu(
              context,
              movie.movieNumber,
              globalPosition,
              isSubscribed: movie.isSubscribed,
            ),
        onMovieToggleCollectionType: hoverActions.toggleCollectionType,
        onMovieBlacklist: hoverActions.blacklist,
      ),
    );
  }

  void _openMovieDetail(BuildContext context, String movieNumber) {
    context.push(_movieDetailPath(movieNumber));
  }

  String _movieDetailPath(String movieNumber) {
    final encoded = Uri.encodeComponent(movieNumber);
    return '$basePath/$encoded';
  }
}

/// 推荐时刻列表共享实现（桌面 / 移动双端壳收敛的 content 层）。
///
/// 平台差异收在壳参数里：`pageSize` / `keyPrefix` / `headerGap` / `backgroundColor` /
/// `fallbackPath` / `previewDrawerKey` / 下拉刷新开关。预览与悬停动作统一走
/// [showMomentPreviewFlow] 的推荐模式（推荐 ID 不当真实时刻 ID 用）。
class DiscoveryMomentsContent extends HookConsumerWidget {
  const DiscoveryMomentsContent({
    super.key,
    required this.pageSize,
    required this.keyPrefix,
    required this.headerGap,
    required this.backgroundColor,
    required this.fallbackPath,
    this.previewDrawerKey,
    this.enablePullToRefresh = false,
  });

  final int pageSize;
  final String keyPrefix;
  final double headerGap;
  final Color backgroundColor;

  /// 预览关闭后的图搜 / 播放 / 影片详情 / 演员详情兜底路径。
  final String fallbackPath;

  final Key? previewDrawerKey;
  final bool enablePullToRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = momentRecommendationFeedProvider(pageSize);
    // 中立化 loadMore 状态：翻页 loading/失败只重建独立页脚，不重建网格。
    final async = ref.watch(
      provider.select(
        (asyncValue) => asyncValue.whenData(withoutLoadMoreStatus),
      ),
    );
    final paged =
        async.value ?? const PagedListState<MomentRecommendationDto>();
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        // 同影片页：loadMore 失败存续期间滚动不自动重试。
        // 读实时状态（build 闭包里的 paged 已做 loadMore 中立化）。
        final loadMoreError =
            ref.read(provider).value?.loadMoreErrorMessage;
        if (loadMoreError == null) {
          unawaited(ref.read(provider.notifier).loadMore());
        }
      },
      triggerOffset: 300,
    );

    final sliver = SliverMainAxisGroup(
      key: Key('$keyPrefix-page'),
      slivers: [
        _buildBody(context, ref, async, paged),
        // loadMore 页脚独立订阅：翻页状态翻转只重建它，不重建上面网格。
        PagedLoadMoreFooterSliver(
          watchFooter: (ref) => ref.watch(
            provider.select((s) {
              final moments = s.value;
              if (moments == null || moments.isEmpty) {
                return null;
              }
              return (
                isLoading: moments.isLoadingMore,
                errorMessage: moments.loadMoreErrorMessage,
              );
            }),
          ),
          onLoadMore: (ref) =>
              unawaited(ref.read(provider.notifier).loadMore()),
        ),
      ],
    );

    return AppFixedHeaderLayout(
      header: SizedBox(height: headerGap),
      child: AppPageRefreshScope(
        onRefresh: () => _handleRefresh(context, ref),
        child: enablePullToRefresh
            ? ColoredBox(
                color: backgroundColor,
                child: AppAdaptiveRefreshScrollView(
                  controller: scrollController,
                  onRefresh: () => _handleRefresh(context, ref),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[sliver],
                ),
              )
            : ColoredBox(
                color: backgroundColor,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [sliver],
                ),
              ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final provider = momentRecommendationFeedProvider(pageSize);
    final errorMessage = await ref.read(provider.notifier).refresh();
    if (errorMessage != null && context.mounted) {
      showToast('刷新失败');
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<PagedListState<MomentRecommendationDto>> async,
    PagedListState<MomentRecommendationDto> paged,
  ) {
    if (async.isLoading && async.value == null) {
      // loading 用占位时刻渲染真实网格，由 [AppSkeletonizer] 灰化。
      return AppSkeletonizer.sliver(
        enabled: true,
        child: MomentSliver(
          items: momentListPlaceholders(count: pageSize),
          onItemTap: _ignoreMomentTap,
        ),
      );
    }
    if (async.hasError) {
      final provider = momentRecommendationFeedProvider(pageSize);
      return SliverToBoxAdapter(
        child: DiscoveryRetryEmptyState(
          message: '推荐时刻加载失败，请稍后重试',
          onRetry: () => ref.read(provider.notifier).reload(),
        ),
      );
    }
    if (paged.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '暂无推荐时刻，播放时添加标记，等定时任务处理后展示'),
      );
    }
    return MomentSliver(
      items: paged.items
          .map((item) => item.toMomentListItem())
          .toList(growable: false),
      onItemTap: (item) => _openMomentPreview(context, item),
      onItemPlay: (item) => unawaited(
        playMomentItem(
          context: context,
          item: item,
          fallbackPath: fallbackPath,
        ),
      ),
      onItemOpenMovie: (item) => openMomentSourceMovie(
        context: context,
        item: item,
        fallbackPath: fallbackPath,
      ),
      onItemAddToCollection: (item) => unawaited(
        addMomentItemToCollection(context, item: item, isRecommendation: true),
      ),
    );
  }

  Future<void> _openMomentPreview(BuildContext context, MomentListItem item) {
    return showMomentPreviewFlow(
      context: context,
      item: item,
      fallbackPath: fallbackPath,
      drawerKey: previewDrawerKey,
      isRecommendation: true,
    );
  }
}

void _ignoreMomentTap(MomentListItem _) {}

class DiscoveryRetryEmptyState extends StatelessWidget {
  const DiscoveryRetryEmptyState({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryKey,
  });

  final String message;
  final Future<void> Function() onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppEmptyState(message: message),
        SizedBox(height: context.appSpacing.md),
        AppButton(
          key: retryKey,
          label: '重试',
          size: AppButtonSize.small,
          onPressed: () => unawaited(onRetry()),
        ),
      ],
    );
  }
}
