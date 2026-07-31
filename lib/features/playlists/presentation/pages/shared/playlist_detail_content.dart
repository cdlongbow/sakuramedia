import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_subscription_change_notifier.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/paged_movie_summary_controller.dart';
import 'package:sakuramedia/features/playlists/data/api/playlists_api.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_detail_controller.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_filter_state.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_resolution_options_controller.dart';
import 'package:sakuramedia/features/playlists/presentation/widgets/playlist_filter_drawer.dart';
import 'package:sakuramedia/features/playlists/presentation/widgets/playlist_filter_sections.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/multi_select_state_mixin.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_pull_to_refresh.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_inline_spinner.dart';
import 'package:sakuramedia/widgets/base/overlays/app_filter_popover.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_batch_selection.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';
import 'package:sakuramedia/widgets/domain/playlists/playlist_banner_card.dart';

import 'package:sakuramedia/features/playlists/presentation/providers/playlists_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';

class PlaylistDetailContent extends ConsumerStatefulWidget {
  const PlaylistDetailContent({
    super.key,
    required this.playlistId,
    required this.onMovieTap,
    this.enablePullToRefresh = false,
  });

  final int playlistId;
  final ValueChanged<MovieListItemDto> onMovieTap;
  final bool enablePullToRefresh;

  @override
  ConsumerState<PlaylistDetailContent> createState() =>
      _PlaylistDetailContentState();
}

class _PlaylistDetailContentState extends ConsumerState<PlaylistDetailContent>
    with
        MultiSelectStateMixin<PlaylistDetailContent, String>,
        MovieBatchSelectionMixin<PlaylistDetailContent> {
  late final PlaylistDetailController _detailController;
  late final PagedMovieSummaryController _moviesController;
  late final MovieSubscriptionChangeNotifier _subscriptionChangeNotifier;
  late final PlaylistsApi _playlistsApi;
  late final PlaylistResolutionOptionsController _resolutionOptionsController;
  PlaylistFilterState _filterState = PlaylistFilterState.initial;

  @override
  String get batchKeyPrefix => 'playlist-detail';

  @override
  MovieBatchToggleExecutor get batchSubscriptionExecutor =>
      _moviesController.batchToggleSubscription;

  @override
  List<String> get batchSelectableNumbers => _moviesController.items
      .map((movie) => movie.movieNumber)
      .toList(growable: false);

  Listenable get _pageListenable =>
      Listenable.merge(<Listenable>[_detailController, _moviesController]);

  @override
  void initState() {
    super.initState();
    _playlistsApi = ref.read(playlistsApiProvider);
    final moviesApi = ref.read(moviesApiProvider);
    _subscriptionChangeNotifier = ref.read(
      movieSubscriptionBroadcasterProvider,
    );
    _subscriptionChangeNotifier.addListener(_onMovieSubscriptionChanged);
    _detailController = PlaylistDetailController(
      playlistId: widget.playlistId,
      fetchPlaylistDetail: _playlistsApi.getPlaylistDetail,
    )..load();
    _resolutionOptionsController = PlaylistResolutionOptionsController(
      playlistsApi: _playlistsApi,
      playlistId: widget.playlistId,
    );
    _moviesController = PagedMovieSummaryController(
      // 筛选状态惰性读取：UI 改完 `_filterState` 后必须 reload() 才会重新走闭包。
      fetchPage:
          (page, pageSize) => _playlistsApi.getPlaylistMovies(
            playlistId: widget.playlistId,
            page: page,
            pageSize: pageSize,
            sort: _filterState.sortExpression,
            resolution: _filterState.resolution?.apiValue,
          ),
      subscribeMovie: moviesApi.subscribeMovie,
      unsubscribeMovie: moviesApi.unsubscribeMovie,
      batchSubscribeMovies: moviesApi.batchSubscribeMovies,
      batchUnsubscribeMovies: moviesApi.batchUnsubscribeMovies,
      onSubscriptionChanged: _reportSubscriptionChange,
      onSubscriptionsBatchChanged: _subscriptionChangeNotifier.reportBatch,
      pageSize: 24,
      loadMoreTriggerOffset: 300,
      initialLoadErrorText: '影片列表加载失败，请稍后重试',
      loadMoreErrorText: '加载更多失败，请点击重试',
    );
    _moviesController.attachScrollListener();
    _moviesController.initialize();
  }

  @override
  void dispose() {
    _subscriptionChangeNotifier.removeListener(_onMovieSubscriptionChanged);
    _detailController.dispose();
    _moviesController.dispose();
    _resolutionOptionsController.dispose();
    super.dispose();
  }

  void _onMovieSubscriptionChanged() {
    _subscriptionChangeNotifier.consumePendingChanges(
      _moviesController.applySubscriptionChanges,
    );
  }

  void _reportSubscriptionChange({
    required String movieNumber,
    required bool isSubscribed,
  }) {
    _subscriptionChangeNotifier.reportChange(
      movieNumber: movieNumber,
      isSubscribed: isSubscribed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageRefreshScope(
      onRefresh: _handleRefresh,
      child: AnimatedBuilder(
        animation: _pageListenable,
        builder: (context, _) {
          if (_detailController.isLoading &&
              _detailController.playlist == null) {
            return const SizedBox.expand(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (_detailController.errorMessage != null ||
              _detailController.playlist == null) {
            return AppEmptyState(
              message: _detailController.errorMessage ?? '播放列表详情暂时无法加载，请稍后重试',
            );
          }

          final playlist = _detailController.playlist!;
          final footer = _buildLoadMoreFooter(context);
          final slivers = <Widget>[
            SliverToBoxAdapter(
              child: PlaylistBannerCard(
                key: Key('playlist-banner-card-${playlist.id}'),
                title: playlist.name,
                coverImageUrl:
                    _moviesController
                        .items
                        .firstOrNull
                        ?.coverImage
                        ?.bestAvailableUrl,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: context.appSpacing.sm),
                child:
                    selectionMode
                        ? buildBatchSelectionToolbar()
                        : _buildListHeader(context),
              ),
            ),
            MovieSummarySliver(
              items: _moviesController.items,
              isLoading: _moviesController.isInitialLoading,
              errorMessage: _moviesController.initialErrorMessage,
              onMovieTap: widget.onMovieTap,
              onMovieMenuRequest:
                  (movie, globalPosition) => requestMovieCollectionMenu(
                    context,
                    movie.movieNumber,
                    globalPosition,
                    isSubscribed: movie.isSubscribed,
                  ),
              onMovieSubscriptionTap:
                  (movie) => _toggleMovieSubscription(movie.movieNumber),
              isMovieSubscriptionUpdating:
                  (movie) => _moviesController.isSubscriptionUpdating(
                    movie.movieNumber,
                  ),
              emptyMessage: _filterState.isDefault ? '暂无影片数据' : '当前筛选条件下暂无匹配影片',
              selectionMode: selectionMode,
              isMovieSelected: (movie) => isSelected(movie.movieNumber),
              onMovieSelectedChanged:
                  (movie, _) => toggleSelect(movie.movieNumber),
            ),
            if (footer != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: context.appSpacing.md),
                  child: footer,
                ),
              ),
          ];
          final scrollView = CustomScrollView(
            physics:
                widget.enablePullToRefresh
                    ? const AlwaysScrollableScrollPhysics()
                    : null,
            controller: _moviesController.scrollController,
            slivers: slivers,
          );

          if (!widget.enablePullToRefresh) {
            return scrollView;
          }

          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
            return AppAdaptiveRefreshScrollView(
              onRefresh: _handleRefresh,
              controller: _moviesController.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: slivers,
            );
          }

          return AppPullToRefresh(onRefresh: _handleRefresh, child: scrollView);
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    try {
      await Future.wait<void>([
        _detailController.refresh(),
        _moviesController.refresh(),
        _resolutionOptionsController.refresh(),
      ]);
    } catch (_) {
      if (mounted) {
        showToast('刷新失败');
      }
    }
  }

  /// 列表顶栏：与影片 / 女优列表共用同一条 `AppListHeader`。
  /// 差别只在筛选面板的容器——桌面就地浮层，移动底部抽屉。
  ///
  /// 分辨率状态通过 [_resolutionOptionsController]（`ChangeNotifier`）传给两端
  /// 面板，桌面/移动都实时跟随后端返回：抽屉不再是打开那一刻的快照，抽屉里
  /// 的重试按钮也能正确刷新数据。
  Widget _buildListHeader(BuildContext context) {
    final isMobile = AppPlatformScope.maybeOf(context) == AppPlatform.mobile;
    return AppListHeader(
      filterButtonKey: const Key('playlist-detail-filter-trigger'),
      filterLabel: _filterState.triggerLabel,
      filterPanelKey: const Key('playlist-detail-filter-panel'),
      onFilterTap: isMobile ? () => unawaited(_openFilterDrawer()) : null,
      filterPanelBuilder:
          isMobile
              ? null
              : (_) => PlaylistFilterSectionGroup(
                filterState: _filterState,
                onChanged: _applyFilter,
                resolutionOptions: _resolutionOptionsController,
              ),
      onFilterPanelOpened:
          isMobile
              ? null
              : () => unawaited(_resolutionOptionsController.ensureLoaded()),
      filterPanelFooter: AppFilterPanelFooter(
        isDefault: _filterState.isDefault,
        onReset: _resetFilters,
      ),
      informationSlots: [
        AppListHeaderInfo(
          key: const Key('playlist-detail-total'),
          label: '${_detailController.playlist?.movieCount ?? 0} 部影片',
        ),
      ],
      actionSlots: [buildEnterSelectionButton()],
    );
  }

  void _applyFilter(PlaylistFilterState nextState) {
    if (nextState.matches(_filterState)) {
      return;
    }
    setState(() => _filterState = nextState);
    // 切筛选跨结果集，选中态失去意义。
    if (selectionMode) {
      exitSelection();
    }
    final controller = _moviesController;
    if (controller.scrollController.hasClients) {
      controller.scrollController.jumpTo(0);
    }
    unawaited(controller.reload());
  }

  void _resetFilters() {
    _applyFilter(PlaylistFilterState.initial);
  }

  Future<void> _openFilterDrawer() async {
    // 分辨率状态通过 controller 订阅，抽屉打开时若还没加载过就触发一次，
    // 加载中/失败/成功的 UI 都由 filter sections 内部随 controller 实时更新，
    // 这里不再需要「先 await 再弹」的规避。
    unawaited(_resolutionOptionsController.ensureLoaded());
    await showMobilePlaylistFilterDrawer(
      context,
      current: _filterState,
      onChanged: _applyFilter,
      resolutionOptions: _resolutionOptionsController,
    );
  }

  Future<void> _toggleMovieSubscription(String movieNumber) async {
    final result = await _moviesController.toggleSubscription(
      movieNumber: movieNumber,
    );
    if (!mounted) {
      return;
    }
    showMovieSubscriptionFeedback(result);
  }

  Widget? _buildLoadMoreFooter(BuildContext context) {
    if (_moviesController.items.isEmpty) {
      return null;
    }

    if (_moviesController.isLoadingMore) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.appSpacing.md),
          child: const AppInlineSpinner(),
        ),
      );
    }

    if (_moviesController.loadMoreErrorMessage == null) {
      return null;
    }

    return Center(
      child: TextButton(
        onPressed: _moviesController.loadMore,
        child: Text(_moviesController.loadMoreErrorMessage!),
      ),
    );
  }
}
