import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/page_cache_keys.dart';
import 'package:sakuramedia/app/providers/riverpod_page_cache_provider.dart';
import 'package:sakuramedia/app/riverpod_page_cache.dart';
import 'package:sakuramedia/features/actors/presentation/controllers/listing/actor_filter_state.dart';
import 'package:sakuramedia/features/actors/presentation/actor_placeholders.dart';
import 'package:sakuramedia/features/actors/presentation/providers/actor_summary_provider.dart';
import 'package:sakuramedia/features/actors/presentation/providers/actor_summary_scope.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_filter_result_loading_overlay.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/overlays/app_filter_popover.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_filter_sections.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_list_search_field.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_summary_grid.dart';

class DesktopActorsPage extends ConsumerStatefulWidget {
  const DesktopActorsPage({super.key});

  @override
  ConsumerState<DesktopActorsPage> createState() => _DesktopActorsPageState();
}

class _DesktopActorsPageState extends ConsumerState<DesktopActorsPage> {
  static const _scope = ActorSummaryScope.desktop();

  late final RiverpodPageHandle _pageCacheHandle;
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreIfNeeded);
    _searchController = TextEditingController(
      text: ref.read(actorSummaryProvider(_scope)).value?.filter.query ?? '',
    );
    _pageCacheHandle = ref
        .read(riverpodPageCacheProvider)
        .obtain(
          key: desktopActorsPageCacheKey(),
          resolveLinks: () {
            final link = ref
                .read(actorSummaryProvider(_scope).notifier)
                .cacheLink;
            return link == null ? const [] : [link];
          },
        );
  }

  @override
  void dispose() {
    _pageCacheHandle.release();
    _searchController.dispose();
    _scrollController
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) {
      return;
    }
    final summary = ref.read(actorSummaryProvider(_scope)).value;
    final position = _scrollController.position;
    if (summary == null ||
        summary.paged.loadMoreErrorMessage != null ||
        position.pixels < position.maxScrollExtent - 300) {
      return;
    }
    unawaited(ref.read(actorSummaryProvider(_scope).notifier).loadMore());
  }

  void _applyFilter(ActorFilterState nextState) {
    final current = ref.read(actorSummaryProvider(_scope)).value?.filter;
    if (current == nextState) {
      return;
    }
    if ((nextState.query ?? '').isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    unawaited(
      ref.read(actorSummaryProvider(_scope).notifier).applyFilter(nextState),
    );
  }

  void _applySearchQuery(String value) {
    final current =
        ref.read(actorSummaryProvider(_scope)).value?.filter ??
        ActorFilterState.initial;
    _applyFilter(current.withSearchQuery(value));
  }

  void _toggleSearch() {
    setState(() => _searchExpanded = !_searchExpanded);
  }

  void _resetFilters() => _applyFilter(ActorFilterState.initial);

  Future<void> _refresh() async {
    await ref.read(actorSummaryProvider(_scope).notifier).refresh();
  }

  Future<void> _toggleActorSubscription(int actorId) async {
    final result = await ref
        .read(actorSummaryProvider(_scope).notifier)
        .toggleSubscription(actorId);
    if (!mounted) {
      return;
    }
    showActorSubscriptionFeedback(result);
  }

  @override
  Widget build(BuildContext context) {
    final actorsAsync = ref.watch(actorSummaryProvider(_scope));
    final summary = actorsAsync.value;
    final paged = summary?.paged;
    final filter = summary?.filter ?? ActorFilterState.initial;
    final items = paged?.items ?? const [];
    final isInitialLoading = actorsAsync.isLoading && summary == null;
    final initialErrorMessage = actorsAsync.hasError && summary == null
        ? '女优列表加载失败，请稍后重试'
        : null;
    final showFooter =
        items.isNotEmpty &&
        (paged!.isLoadingMore || paged.loadMoreErrorMessage != null);

    return AppPageRefreshScope(
      onRefresh: _refresh,
      child: ColoredBox(
        color: context.appColors.surfaceElevated,
        child: AppFixedHeaderLayout(
          header: Column(
            key: const Key('actors-page'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActorsHeader(
                total: paged?.total ?? 0,
                filterState: filter,
                filterUpdate:
                    paged?.filterUpdate ?? const FilterUpdateState.idle(),
                hasPreviousItems: items.isNotEmpty,
                onRetryFilter: () => unawaited(
                  ref.read(actorSummaryProvider(_scope).notifier).retryFilter(),
                ),
                onFilterChanged: _applyFilter,
                onResetFilters: _resetFilters,
                searchExpanded: _searchExpanded,
                searchToggle: ActorListSearchToggle(
                  key: const Key('actors-search-toggle'),
                  isActive: _searchExpanded || filter.query != null,
                  tooltip: _searchExpanded ? '收起搜索' : '搜索女优',
                  onTap: _toggleSearch,
                ),
                searchField: ActorListSearchField(
                  fieldKey: const Key('actors-search-field'),
                  clearButtonKey: const Key('actors-search-clear'),
                  controller: _searchController,
                  onChanged: _applySearchQuery,
                ),
              ),
              SizedBox(height: context.appSpacing.lg),
            ],
          ),
          child: AppFilterResultLoadingOverlay(
            isLoading: paged?.filterUpdate.isLoading ?? false,
            hasPreviousItems: items.isNotEmpty,
            child: CustomScrollView(
              key: const PageStorageKey<String>('desktop:actors:list'),
              controller: _scrollController,
              slivers: [
                SliverMainAxisGroup(
                  slivers: [
                    if (!(paged?.filterUpdate.hasFailed ?? false) ||
                        items.isNotEmpty)
                      AppSkeletonizer.sliver(
                        enabled: isInitialLoading,
                        child: ActorSummarySliver(
                          items: isInitialLoading
                              ? actorListItemPlaceholders(count: 24)
                              : items,
                          errorMessage: initialErrorMessage,
                          onActorTap: (actor) => context.pushDesktopActorDetail(
                            actorId: actor.id,
                            fallbackPath: desktopActorsPath,
                          ),
                          onActorSubscriptionTap: (actor) =>
                              _toggleActorSubscription(actor.id),
                          isActorSubscriptionUpdating: (actor) =>
                              summary?.isSubscriptionUpdating(actor.id) ??
                              false,
                          emptyMessage: filter.isDefault
                              ? '暂无女优，去搜索看看吧'
                              : '当前筛选条件下暂无匹配女优',
                        ),
                      ),
                    if (showFooter)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: context.appSpacing.md),
                          child: AppPagedLoadMoreFooter(
                            isLoading: paged.isLoadingMore,
                            errorMessage: paged.loadMoreErrorMessage,
                            onRetry: () => ref
                                .read(actorSummaryProvider(_scope).notifier)
                                .loadMore(),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActorsHeader extends StatelessWidget {
  const _ActorsHeader({
    required this.total,
    required this.filterState,
    required this.filterUpdate,
    required this.hasPreviousItems,
    required this.onRetryFilter,
    required this.onFilterChanged,
    required this.onResetFilters,
    required this.searchExpanded,
    required this.searchToggle,
    required this.searchField,
  });

  final int total;
  final ActorFilterState filterState;
  final FilterUpdateState filterUpdate;
  final bool hasPreviousItems;
  final VoidCallback onRetryFilter;
  final ValueChanged<ActorFilterState> onFilterChanged;
  final VoidCallback onResetFilters;
  final bool searchExpanded;
  final Widget searchToggle;
  final Widget searchField;

  @override
  Widget build(BuildContext context) {
    return AppListHeader(
      filterButtonKey: const Key('actors-filter-trigger'),
      filterLabel: filterState.triggerLabel,
      filterPanelKey: const Key('actors-filter-panel'),
      filterPanelExtraWidth: 260,
      filterPanelBuilder: (_) => ActorFilterSectionGroup(
        filterState: filterState,
        onChanged: onFilterChanged,
      ),
      filterPanelFooter: AppFilterPanelFooter(
        isDefault: filterState.isDefault,
        onReset: onResetFilters,
      ),
      filterUpdate: filterUpdate,
      hasPreviousFilterItems: hasPreviousItems,
      onRetryFilter: onRetryFilter,
      informationSlots: searchExpanded
          ? const <Widget>[]
          : <Widget>[
              AppListHeaderInfo(
                key: const Key('actors-page-total'),
                label: '$total 位',
              ),
            ],
      actionSlots: searchExpanded ? const <Widget>[] : <Widget>[searchToggle],
      center: searchExpanded
          ? Row(
              children: [
                AppListHeaderInfo(
                  key: const Key('actors-page-total'),
                  label: '$total 位',
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Row(
                    children: [
                      Expanded(child: searchField),
                      SizedBox(width: context.appSpacing.sm),
                      searchToggle,
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
