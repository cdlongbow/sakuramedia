import 'package:sakuramedia/features/status/presentation/providers/server_capabilities_provider.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:sakuramedia/features/clips/presentation/widgets/create_clip_dialog.dart';
import 'package:sakuramedia/features/media/data/media_point_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_review_dto.dart';
import 'package:sakuramedia/features/movies/presentation/movie_placeholders.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_detail_magnet_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_detail_review_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_detail_thumbnail_provider.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_filter_result_loading_overlay.dart';
import 'package:sakuramedia/widgets/base/feedback/app_filter_update_bar.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_selectable_text_scroll_configuration.dart';
import 'package:sakuramedia/widgets/base/media/images/app_image_action_menu.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';
import 'package:sakuramedia/widgets/domain/media/media_thumbnail_action_support.dart';
import 'package:sakuramedia/widgets/domain/media/media_thumbnail_tab.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_plot_preview_overlay.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_magnet_search_content.dart';

/// 检查器承载的功能：评论 / 磁力搜索 / 缩略图。
///
/// 每个入口只弹**一个功能**的弹窗，面板内不再放页签——入口键已经决定了要看
/// 什么，再摆一排 tab 等于同一件事问两遍。
enum MovieDetailInspectorPane { review, magnetSearch, thumbnail }

/// 单个功能的弹窗内容：一行标题 + 对应功能内容。
///
/// 三个 provider 都是 autoDispose family，面板负责收编并关闭它们在本弹窗
/// 生命周期内的 `KeepAliveLink`（见 [_MovieDetailInspectorPanelState]）。
class MovieDetailInspectorPanel extends ConsumerStatefulWidget {
  const MovieDetailInspectorPanel({
    super.key,
    required this.movieNumber,
    required this.selectedMedia,
    required this.pane,
    this.thumbnailPreviewPresentation = MoviePlotPreviewPresentation.dialog,
    this.onSearchSimilar,
    this.onPlay,
  });

  final String movieNumber;
  final MovieMediaItemDto? selectedMedia;

  /// 本弹窗承载的功能（由入口键决定，弹窗内不可切换）。
  final MovieDetailInspectorPane pane;
  final MoviePlotPreviewPresentation thumbnailPreviewPresentation;
  final Future<void> Function(
    MovieMediaThumbnailDto thumbnail,
    String imageUrl,
    String fileName,
  )?
  onSearchSimilar;
  final void Function(MovieMediaThumbnailDto thumbnail)? onPlay;

  @override
  ConsumerState<MovieDetailInspectorPanel> createState() =>
      _MovieDetailInspectorPanelState();
}

class _MovieDetailInspectorPanelState
    extends ConsumerState<MovieDetailInspectorPanel> {
  /// 本弹窗对应 provider 的 `KeepAliveLink`。
  ///
  /// 三个 provider 都是 autoDispose family，build 里自持 `ref.keepAlive()`——
  /// link 必须由**面板**关闭：弹窗打开期间保活，[dispose] 时 close → provider
  /// 释放。若无人 close 会形成「link 不关 → provider 永不 dispose → onDispose
  /// 里的 close 永不执行」的死锁式泄漏（见 `lib/features/AGENTS.md`「状态与数据」）。
  KeepAliveLink? _retainedLink;

  MovieDetailReview get _reviewController =>
      ref.read(movieDetailReviewProvider(widget.movieNumber).notifier);
  MovieDetailMagnet get _magnetController =>
      ref.read(movieDetailMagnetProvider(widget.movieNumber).notifier);
  MovieDetailThumbnail get _thumbnailController => ref.read(
    movieDetailThumbnailProvider(
      mediaId: widget.selectedMedia?.mediaId,
    ).notifier,
  );
  MovieDetailThumbnailState get _thumbnailState => ref.read(
    movieDetailThumbnailProvider(mediaId: widget.selectedMedia?.mediaId),
  );

  @override
  void initState() {
    super.initState();
    // 收编在 initState 同步做（不等 post-frame）：link 是 provider 在 build 里
    // 自持的，只要 provider 被创建就已存在——晚一帧收编，中途被销毁就没人 close。
    switch (widget.pane) {
      case MovieDetailInspectorPane.review:
        _retainedLink = _reviewController.cacheLink;
      case MovieDetailInspectorPane.magnetSearch:
        _retainedLink = _magnetController.cacheLink;
      case MovieDetailInspectorPane.thumbnail:
        _retainedLink = _thumbnailController.cacheLink;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.pane) {
        case MovieDetailInspectorPane.review:
          unawaited(_reviewController.loadInitial());
        case MovieDetailInspectorPane.magnetSearch:
          // 磁力搜索等用户点「搜索资源」，不预加载。
          break;
        case MovieDetailInspectorPane.thumbnail:
          unawaited(_thumbnailController.loadIfNeeded());
      }
    });
  }

  @override
  void dispose() {
    _retainedLink?.close();
    _retainedLink = null;
    super.dispose();
  }

  Future<void> _showThumbnailActions(int index, Offset globalPosition) async {
    final thumbnails = _thumbnailState.thumbnails;
    if (index < 0 || index >= thumbnails.length) {
      return;
    }
    final thumbnail = thumbnails[index];
    final point = await findMediaPointForThumbnail(
      ref: ref,
      thumbnail: thumbnail,
    );
    if (!mounted) {
      return;
    }
    final action = await showAppActionMenu<AppImageActionType>(
      context: context,
      globalPosition: globalPosition,
      items: buildImageActionMenuItems(
        buildMediaThumbnailActionDescriptors(
          showSearchSimilar: ref.read(imageSearchEnabledProvider),
          thumbnail: thumbnail,
          point: point,
          canSearchSimilar: widget.onSearchSimilar != null,
          canPlay: widget.onPlay != null,
        ),
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    await _handleThumbnailAction(thumbnail, action, point);
  }

  Future<void> _handleCreateClip() async {
    final start = _thumbnailState.clipStartThumbnail;
    final end = _thumbnailState.clipEndThumbnail;
    if (start == null || end == null || start.mediaId <= 0) {
      return;
    }
    final created = await showCreateClipDialog(
      context,
      mediaId: start.mediaId,
      movieNumber: widget.movieNumber,
      startThumbnailId: start.thumbnailId,
      endThumbnailId: end.thumbnailId,
      startSeconds: start.offsetSeconds,
      endSeconds: end.offsetSeconds,
    );
    if (!mounted || created == null) {
      return;
    }
    showToast('切片已生成');
    // 退出圈选模式并清空已选点。
    _thumbnailController.toggleClipSelectionMode();
  }

  Future<void> _handleThumbnailAction(
    MovieMediaThumbnailDto thumbnail,
    AppImageActionType action,
    MediaPointDto? point,
  ) async {
    final fileName =
        'movie_thumbnail_${widget.movieNumber}_${thumbnail.thumbnailId}.webp';
    final imageUrl = thumbnail.image.origin;
    await handleMediaThumbnailAction(
      context: context,
      ref: ref,
      thumbnail: thumbnail,
      action: action,
      point: point,
      fileName: fileName,
      onSearchSimilar: widget.onSearchSimilar == null
          ? null
          : () async {
              Navigator.of(context).pop();
              await Future<void>.microtask(
                () => widget.onSearchSimilar!(thumbnail, imageUrl, fileName),
              );
            },
      onPlay: widget.onPlay == null
          ? null
          : () async {
              Navigator.of(context).pop();
              await Future<void>.microtask(() => widget.onPlay!(thumbnail));
            },
    );
  }

  String get _title => switch (widget.pane) {
    MovieDetailInspectorPane.review => '评论',
    MovieDetailInspectorPane.magnetSearch => '磁力搜索',
    MovieDetailInspectorPane.thumbnail => '缩略图',
  };

  Widget _buildContent() {
    return switch (widget.pane) {
      MovieDetailInspectorPane.review => _MovieDetailReviewTab(
        movieNumber: widget.movieNumber,
      ),
      MovieDetailInspectorPane.magnetSearch => MovieMagnetSearchContent(
        movieNumber: widget.movieNumber,
      ),
      MovieDetailInspectorPane.thumbnail => MediaThumbnailTab(
        mediaId: widget.selectedMedia?.mediaId,
        thumbnailPreviewPresentation: widget.thumbnailPreviewPresentation,
        onThumbnailMenuRequested: _showThumbnailActions,
        onCreateClip: _handleCreateClip,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('movie-detail-inspector-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题右侧给关闭按钮留位（移动端抽屉没有关闭按钮，留白无害）。
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: context.appComponentTokens.buttonHeightMd,
          ),
          child: Text(
            _title,
            key: const Key('movie-detail-inspector-title'),
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s16,
              weight: AppTextWeight.semibold,
              tone: AppTextTone.primary,
            ),
          ),
        ),
        SizedBox(height: context.appSpacing.md),
        Expanded(child: _buildContent()),
      ],
    );
  }
}

class _MovieDetailReviewTab extends ConsumerStatefulWidget {
  const _MovieDetailReviewTab({required this.movieNumber});

  final String movieNumber;

  @override
  ConsumerState<_MovieDetailReviewTab> createState() =>
      _MovieDetailReviewTabState();
}

class _MovieDetailReviewTabState extends ConsumerState<_MovieDetailReviewTab> {
  MovieDetailReview get _controller =>
      ref.read(movieDetailReviewProvider(widget.movieNumber).notifier);
  MovieDetailReviewState get _state =>
      ref.read(movieDetailReviewProvider(widget.movieNumber));

  static const double _loadMoreExtentAfterThreshold = 200;
  late final ScrollController _scrollController;
  int _lastAutoLoadTriggerItemCount = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter >
        _loadMoreExtentAfterThreshold) {
      _lastAutoLoadTriggerItemCount = -1;
      return;
    }
    if (_state.items.length == _lastAutoLoadTriggerItemCount) {
      return;
    }
    _lastAutoLoadTriggerItemCount = _state.items.length;
    _controller.loadMore();
  }

  void _handleSortChange(MovieReviewSort sort) {
    if (_state.sort == sort) {
      return;
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _lastAutoLoadTriggerItemCount = -1;
    unawaited(_controller.setSort(sort));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movieDetailReviewProvider(widget.movieNumber));
    return Padding(
      padding: EdgeInsets.only(
        top: context.appSpacing.sm,
        bottom: context.appSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.appSpacing.xs,
            runSpacing: context.appSpacing.xs,
            children: [
              for (final sort in MovieReviewSort.values)
                AppTextButton(
                  key: Key('movie-detail-review-sort-${sort.apiValue}'),
                  label: sort.label,
                  size: AppTextButtonSize.xSmall,
                  isSelected: state.sort == sort,
                  selectedStyle: AppTextButtonSelectedStyle.plain,
                  onPressed: () => _handleSortChange(sort),
                ),
            ],
          ),
          AppFilterUpdateBar(
            state: state.filterUpdate,
            hasPreviousItems: state.items.isNotEmpty,
            onRetry: () => unawaited(_controller.retrySort()),
          ),
          SizedBox(height: context.appSpacing.sm),
          Expanded(
            child: AppFilterResultLoadingOverlay(
              surfaceColor: context.appColors.surfaceCard,
              isLoading: state.filterUpdate.isLoading,
              hasPreviousItems: state.items.isNotEmpty,
              child: _buildContent(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MovieDetailReviewState state) {
    if (state.filterUpdate.hasFailed && state.items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (state.isInitialLoading && state.items.isEmpty) {
      return const _MovieDetailReviewLoadingList();
    }

    if (state.initialErrorMessage != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.initialErrorMessage!,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s14,
                weight: AppTextWeight.regular,
                tone: AppTextTone.secondary,
              ),
            ),
            SizedBox(height: context.appSpacing.md),
            AppButton(
              key: const Key('movie-detail-review-retry-button'),
              label: '重试',
              variant: AppButtonVariant.secondary,
              onPressed: _controller.loadInitial,
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(child: AppEmptyState(message: '暂无评论'));
    }

    return AppSelectableTextScrollConfiguration(
      child: ListView.separated(
        controller: _scrollController,
        key: const Key('movie-detail-review-list'),
        itemCount: state.items.length + 1,
        separatorBuilder: (context, index) =>
            SizedBox(height: context.appSpacing.sm),
        itemBuilder: (context, index) {
          if (index < state.items.length) {
            return _MovieDetailReviewCard(review: state.items[index]);
          }
          return _MovieDetailReviewFooter(
            state: state,
            onRetryLoadMore: _controller.loadMore,
          );
        },
      ),
    );
  }
}

class _MovieDetailReviewCard extends StatelessWidget {
  const _MovieDetailReviewCard({required this.review});

  final MovieReviewDto review;

  @override
  Widget build(BuildContext context) {
    final reviewDate = review.createdAt == null
        ? '--/--/--'
        : DateFormat('yy/MM/dd').format(review.createdAt!.toLocal());
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.appSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.mdBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.appSpacing.xs,
            runSpacing: context.appSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                review.username.trim().isEmpty ? '匿名用户' : review.username,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.secondary,
                ),
              ),
              Text(
                reviewDate,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.secondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: context.appComponentTokens.iconSizeXs,
                    color: context.appColors.movieDetailScoreIcon,
                  ),
                  SizedBox(width: context.appSpacing.xs),
                  Text(
                    '${review.score}',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.muted,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.thumb_up_alt_rounded,
                    size: context.appComponentTokens.iconSizeXs,
                    color: context.appColors.movieCardPlayableBadgeBackground,
                  ),
                  SizedBox(width: context.appSpacing.xs),
                  Text(
                    '${review.likeCount}',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.appSpacing.xs),
          SelectableText(
            review.content.trim().isEmpty ? '暂无评论内容' : review.content,
            key: const Key('movie-detail-review-content'),
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s14,
              weight: AppTextWeight.regular,
              tone: AppTextTone.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieDetailReviewFooter extends StatelessWidget {
  const _MovieDetailReviewFooter({
    required this.state,
    required this.onRetryLoadMore,
  });

  final MovieDetailReviewState state;
  final VoidCallback onRetryLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.appSpacing.sm),
        child: Center(
          child: CircularProgressIndicator.adaptive(
            key: Key('movie-detail-review-load-more-progress'),
          ),
        ),
      );
    }

    if (state.loadMoreErrorMessage != null) {
      return Column(
        key: const Key('movie-detail-review-load-more-error'),
        children: [
          Text(
            state.loadMoreErrorMessage!,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.regular,
              tone: AppTextTone.muted,
            ),
          ),
          SizedBox(height: context.appSpacing.sm),
          AppButton(
            key: const Key('movie-detail-review-load-more-retry-button'),
            label: '重试加载更多',
            size: AppButtonSize.xSmall,
            variant: AppButtonVariant.secondary,
            onPressed: onRetryLoadMore,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _MovieDetailReviewLoadingList extends StatelessWidget {
  const _MovieDetailReviewLoadingList();

  static const int _minimumSkeletonCount = 3;
  static const double _skeletonLineHeight = 12;
  static const int _skeletonLineCount = 3;
  static const int _internalGapCount = 2;

  int _resolveSkeletonCount(BuildContext context, BoxConstraints constraints) {
    final availableHeight = constraints.maxHeight;
    if (!availableHeight.isFinite) {
      return _minimumSkeletonCount;
    }

    final spacing = context.appSpacing;
    final itemHeight =
        (spacing.md * 2) +
        (_skeletonLineHeight * _skeletonLineCount) +
        (spacing.xs * _internalGapCount);
    final separatorHeight = spacing.sm;
    final estimatedCount =
        ((availableHeight + separatorHeight) / (itemHeight + separatorHeight))
            .ceil();
    return math.max(_minimumSkeletonCount, estimatedCount);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemCount = _resolveSkeletonCount(context, constraints);
        final placeholders = movieReviewPlaceholders(count: itemCount);
        // loading 用占位评论渲染真实卡片，由 [AppSkeletonizer] 灰化。
        return AppSkeletonizer(
          enabled: true,
          child: ListView.separated(
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                SizedBox(height: context.appSpacing.sm),
            itemBuilder: (context, index) => KeyedSubtree(
              key: Key('movie-detail-review-skeleton-$index'),
              child: _MovieDetailReviewCard(review: placeholders[index]),
            ),
          ),
        );
      },
    );
  }
}
