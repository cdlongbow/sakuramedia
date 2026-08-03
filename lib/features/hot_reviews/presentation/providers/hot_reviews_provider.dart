import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_review_list_item_dto.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_review_period.dart';
import 'package:sakuramedia/features/hot_reviews/presentation/providers/hot_reviews_api_provider.dart';
import 'package:sakuramedia/features/hot_reviews/presentation/providers/hot_reviews_state.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';

part 'hot_reviews_provider.g.dart';

/// 热评分页列表（周期筛选驱动,`FilterablePagedAsyncNotifierMixin` 首个采用者）。
///
/// - 切周期走 [FilterReloadStrategy.spinner]（默认）:清列表闪骨架,与迁移前
///   `setPeriod → reload()` 的视觉一致。
/// - autoDispose:离开页面即释放,对齐迁移前控制器随页面 State 生灭。
///
/// 迁移前对应:`PagedHotReviewController`(含「占位 fetchPage 抛
/// UnimplementedError 再 override」的注入 hack,mixin 的 [activeFilter]
/// 使该 hack 自然消失)。
@Riverpod(retry: kNoAsyncNotifierRetry)
class HotReviews extends _$HotReviews
    with
        PagedAsyncNotifierMixin<HotReviewsState, HotReviewListItemDto>,
        FilterablePagedAsyncNotifierMixin<
          HotReviewsState,
          HotReviewListItemDto,
          HotReviewPeriod
        > {
  @override
  int get pageSize => 20;

  @override
  String get initialLoadErrorText => '热评加载失败，请稍后重试';

  @override
  String get loadMoreErrorText => '加载更多失败，请点击重试';

  @override
  HotReviewPeriod get initialFilter => HotReviewPeriod.weekly;

  /// 当前生效周期,供页面在 [AsyncLoading] 期间（state 无值）渲染顶栏标签,
  /// 避免切周期加载中标签闪回默认值。
  HotReviewPeriod get period => activeFilter;

  @override
  PagedListState<HotReviewListItemDto> pagedOf(HotReviewsState s) => s.paged;

  @override
  HotReviewsState applyPaged(
    HotReviewsState s,
    PagedListState<HotReviewListItemDto> paged,
  ) => s.copyWith(paged: paged);

  @override
  HotReviewsState applyFilterToState(
    HotReviewsState s,
    HotReviewPeriod filter,
  ) => s.copyWith(period: filter);

  @override
  Future<PaginatedResponseDto<HotReviewListItemDto>> fetchPage(
    int page,
    int pageSize,
  ) => ref
      .read(hotReviewsApiProvider)
      .getHotReviews(period: activeFilter, page: page, pageSize: pageSize);

  @override
  Future<HotReviewsState> build() async {
    attachDisposeGuard();
    final paged = await loadInitialPage();
    return HotReviewsState(paged: paged, period: activeFilter);
  }
}
