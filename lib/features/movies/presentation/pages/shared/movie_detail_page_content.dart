import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/core/format/media_timecode.dart';
import 'package:sakuramedia/features/clips/data/dto/media_clip_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/player/movie_subtitle_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_actor_wrap.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_hero_card.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_info_block.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_inspector_panel.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_section.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_clip_strip.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_media_item_list.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_plot_gallery.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_ranking_list.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_similar_movie_strip.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_subtitle_section.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_tag_wrap.dart';

/// 详情正文滚动容器的装配入口：正文以 slivers 形式交出（移动端要套下拉刷新
/// 容器），默认走 [CustomScrollView]。
typedef MovieDetailScrollViewBuilder =
    Widget Function(
      BuildContext context,
      List<Widget> slivers,
      ScrollPhysics? scrollPhysics,
    );

class MovieDetailPageContent extends StatelessWidget {
  /// 正文滚动容器（桌面 [CustomScrollView] / 移动端下拉刷新容器）的测试锚点。
  static const Key scrollViewKey = Key('movie-detail-scroll-view');

  const MovieDetailPageContent({
    this.showSimilarMovies = true,
    super.key,
    required this.surfaceColor,
    required this.movie,
    required this.selectedPreviewKey,
    required this.selectedPreviewUrl,
    required this.isSubscribed,
    required this.isSubscriptionUpdating,
    required this.selectedMediaId,
    required this.similarMovies,
    required this.isSimilarMoviesLoading,
    required this.onInspectorPaneTap,
    required this.onPlaylistTap,
    required this.onMediaSelect,
    this.isDeletingSelectedMedia = false,
    this.onDeleteSelectedMedia,
    this.mediaItemsOverride,
    this.onOpenMediaPointPreview,
    this.onRequestMediaPointMenu,
    this.onPlayTap,
    this.mergePlaybackLabel,
    this.onMergePlaybackTap,
    this.isMergePlaybackLoading = false,
    this.onSubscriptionTap,
    this.onMoreActionsTap,
    this.onActorTap,
    this.onSeriesTap,
    this.onTagTap,
    this.onRequestPlotImageMenu,
    this.onOpenPlotPreview,
    this.similarMoviesErrorMessage,
    this.onRetrySimilarMovies,
    this.onSimilarMovieTap,
    this.clips = const <MediaClipDto>[],
    this.isClipsLoading = false,
    this.clipsErrorMessage,
    this.onRetryClips,
    this.onOpenClipActions,
    this.onPlayClip,
    this.onRenameClip,
    this.onDeleteClip,
    this.onAddClipToCollection,
    this.subtitleItems = const <MovieSubtitleItemDto>[],
    this.isSubtitlesLoading = false,
    this.subtitleErrorMessage,
    this.onRetrySubtitles,
    this.onOpenSubtitle,
    this.contentPadding = EdgeInsets.zero,
    this.scrollPhysics,
    this.scrollViewBuilder,
    this.isMoreActionsUpdating = false,
    this.isPlayLoading = false,
  });

  final MovieDetailDto movie;
  final Color surfaceColor;
  final List<MovieMediaItemDto>? mediaItemsOverride;
  final String selectedPreviewKey;
  final String? selectedPreviewUrl;
  final bool isSubscribed;
  final bool isSubscriptionUpdating;
  final bool isMoreActionsUpdating;
  final int? selectedMediaId;
  final List<MovieListItemDto> similarMovies;
  final bool isSimilarMoviesLoading;

  /// 点击操作列的评论 / 磁力搜索 / 缩略图键：打开对应功能的弹窗。
  final ValueChanged<MovieDetailInspectorPane> onInspectorPaneTap;
  final VoidCallback onPlaylistTap;
  final ValueChanged<MovieMediaItemDto> onMediaSelect;
  final bool isDeletingSelectedMedia;
  final ValueChanged<MovieMediaItemDto>? onDeleteSelectedMedia;
  final void Function(MovieMediaItemDto mediaItem, MovieMediaPointDto point)?
  onOpenMediaPointPreview;
  final Future<void> Function(
    BuildContext context,
    MovieMediaItemDto mediaItem,
    MovieMediaPointDto point,
    Offset globalPosition,
  )?
  onRequestMediaPointMenu;
  final VoidCallback? onPlayTap;
  final String? mergePlaybackLabel;
  final VoidCallback? onMergePlaybackTap;
  final bool isMergePlaybackLoading;
  final VoidCallback? onSubscriptionTap;
  final Future<void> Function(Offset globalPosition)? onMoreActionsTap;
  final ValueChanged<MovieActorDto>? onActorTap;
  final VoidCallback? onSeriesTap;
  final ValueChanged<MovieTagDto>? onTagTap;
  final Future<void> Function(
    BuildContext context,
    int index,
    Offset globalPosition,
  )?
  onRequestPlotImageMenu;
  final ValueChanged<int>? onOpenPlotPreview;
  final String? similarMoviesErrorMessage;
  final VoidCallback? onRetrySimilarMovies;
  final ValueChanged<MovieListItemDto>? onSimilarMovieTap;
  final List<MediaClipDto> clips;
  final bool isClipsLoading;
  final String? clipsErrorMessage;
  final VoidCallback? onRetryClips;

  /// 点击切片卡：打开动作面板。
  final ValueChanged<MediaClipDto>? onOpenClipActions;

  /// 切片卡悬停播放键：直接播放。
  final ValueChanged<MediaClipDto>? onPlayClip;
  final ValueChanged<MediaClipDto>? onRenameClip;
  final ValueChanged<MediaClipDto>? onDeleteClip;
  final ValueChanged<MediaClipDto>? onAddClipToCollection;
  final List<MovieSubtitleItemDto> subtitleItems;
  final bool isSubtitlesLoading;
  final String? subtitleErrorMessage;
  final Future<void> Function()? onRetrySubtitles;
  final Future<void> Function(MovieSubtitleItemDto item)? onOpenSubtitle;
  final EdgeInsetsGeometry contentPadding;
  final ScrollPhysics? scrollPhysics;
  final MovieDetailScrollViewBuilder? scrollViewBuilder;

  /// 播放动作进行中（合并播放探测/拉起外部播放器），透传给 hero 播放按钮显示 loading。
  final bool isPlayLoading;

  final bool showSimilarMovies;

  /// 当前是否真的有封面图：桌面用视口上限加高、信息块上叠只对「有封面」生效，
  /// 没有封面时不为一块纯色占位撑满一屏。
  bool get _hasCover =>
      selectedPreviewUrl != null && selectedPreviewUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 整页模糊背景：封面高斯模糊铺底 + 底色罩一层，保证下方文字可读。
        // 背景固定不随滚动，封面切换时才重绘一次。
        Positioned.fill(
          child: _MovieDetailBackground(
            url: selectedPreviewUrl,
            baseColor: surfaceColor,
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportHeight = _resolveViewportHeight(
                context,
                constraints,
              );
              final heroFit = _resolveHeroFit(constraints);
              final heroHeight = _resolveHeroHeight(
                constraints,
                viewportHeight,
                heroFit,
                hasCover: _hasCover,
              );
              final slivers = <Widget>[
                SliverPadding(
                  padding: contentPadding,
                  sliver: _buildDetailBody(
                    context: context,
                    heroHeight: heroHeight,
                    heroFit: heroFit,
                  ),
                ),
              ];
              return scrollViewBuilder?.call(context, slivers, scrollPhysics) ??
                  CustomScrollView(
                    key: scrollViewKey,
                    physics: scrollPhysics,
                    slivers: slivers,
                  );
            },
          ),
        ),
      ],
    );
  }

  MovieMediaProgressDto? get _latestProgress {
    MovieMediaProgressDto? latest;
    for (final media in movie.mediaItems) {
      final progress = media.progress;
      if (progress == null) continue;
      if (latest == null ||
          (progress.lastWatchedAt != null &&
              (latest.lastWatchedAt == null ||
                  progress.lastWatchedAt!.isAfter(latest.lastWatchedAt!)))) {
        latest = progress;
      }
    }
    return latest;
  }

  Widget _buildPlaylistMembership(BuildContext context) {
    final style = resolveAppTextStyle(
      context,
      size: AppTextSize.s12,
      tone: AppTextTone.muted,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.only(bottom: context.appSpacing.sm),
          child: Wrap(
            spacing: context.appSpacing.sm,
            runSpacing: context.appSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('已加入', style: style),
              for (final playlist in movie.playlists.take(2))
                Tooltip(
                  message: playlist.name,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.appSpacing.sm,
                        vertical: context.appSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceMuted,
                        borderRadius: context.appRadius.smBorder,
                      ),
                      child: Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          tone: AppTextTone.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (movie.playlists.length > 2)
                Text('共 ${movie.playlists.length} 个', style: style),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailBody({
    required BuildContext context,
    required double heroHeight,
    required BoxFit heroFit,
  }) {
    final hoverActions = movieCardHoverFeatureActions(context);
    final progress = _latestProgress;
    final watchLabel = progress == null
        ? null
        : '上次看到 ${formatMediaTimecode(progress.lastPositionSeconds)}';
    final watchedAt = progress?.lastWatchedAt?.toLocal();
    final mediaItems = mediaItemsOverride ?? movie.mediaItems;
    final normalizedMergePlaybackLabel = mergePlaybackLabel?.trim() ?? '';
    final orderedActors = <MovieActorDto>[
      ...movie.actors.where((actor) => actor.isFemale),
      ...movie.actors.where((actor) => !actor.isFemale),
    ];

    // 首屏两块（Hero / 信息块）整幅铺满，其余正文区块统一左右留白。
    // 两块常驻构建（都在首帧视口内）；[Key('movie-detail-page')] 挂在盒模型上，
    // 测试里的 getTopLeft 才能取到页面左缘。
    // 首屏两块叠一层：信息块上提 [_desktopHeroInfoOverlapFactor] × Hero 高，
    // 前面一段压在封面下沿（只 PC）。封面高度不变，页面总高随之缩短。
    final infoOverlap = _resolveHeroInfoOverlap(
      heroHeight,
      heroFit,
      hasCover: _hasCover,
    );
    final header = Column(
      key: const Key('movie-detail-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight,
              child: MovieDetailHeroCard(
                height: heroHeight,
                mainImageKey: selectedPreviewKey,
                mainImageUrl: selectedPreviewUrl,
                heroFit: heroFit,
                veilColor: surfaceColor,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: heroHeight - infoOverlap),
              child: SizedBox(
                // 撑满可用宽度：Stack 里只有这一个非定位子节点，它决定整块宽度。
                width: double.infinity,
                child: MovieDetailInfoBlock(
                  overlayTitle: _resolveOverlayTitle(movie),
                  metaItems: _resolveMetaItems(context, movie),
                  fileSizeLabel: _resolveFileSizeLabel(
                    mediaItems,
                    selectedMediaId,
                  ),
                  watchLabel: watchLabel,
                  watchTooltip: watchedAt == null
                      ? watchLabel
                      : '$watchLabel · ${DateFormat('yyyy年M月d日 HH:mm').format(watchedAt)}',
                  isSubscribed: isSubscribed,
                  onSubscriptionTap: onSubscriptionTap,
                  isSubscriptionUpdating: isSubscriptionUpdating,
                  onPlaylistTap: onPlaylistTap,
                  playlistTooltip: movie.playlists.isEmpty
                      ? '加入播放列表'
                      : '管理播放列表',
                  onMoreActionsTap: onMoreActionsTap,
                  isMoreActionsUpdating: isMoreActionsUpdating,
                  isPlayLoading: isPlayLoading,
                  onPlayTap: onPlayTap,
                  mergePlaybackLabel: normalizedMergePlaybackLabel.isEmpty
                      ? null
                      : normalizedMergePlaybackLabel,
                  onMergePlaybackTap: onMergePlaybackTap,
                  isMergePlaybackLoading: isMergePlaybackLoading,
                  onInspectorPaneTap: onInspectorPaneTap,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final sections = <Widget>[
      if (movie.plotImages.isNotEmpty) ...[
        SizedBox(height: context.appSpacing.lg),
        MoviePlotGallery(
          plotImages: movie.plotImages,
          onRequestImageMenu: onRequestPlotImageMenu,
          onOpenPreview: onOpenPlotPreview,
        ),
      ],
      SizedBox(height: context.appComponentTokens.movieDetailSectionGap),
      if (movie.preferredDescription.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(
            bottom: context.appComponentTokens.movieDetailSectionGap,
          ),
          child: Text(
            movie.preferredDescription,
            key: const Key('movie-detail-summary'),
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s14,
              weight: AppTextWeight.regular,
              tone: AppTextTone.secondary,
            ),
          ),
        ),
      if (movie.playlists.isNotEmpty) _buildPlaylistMembership(context),
      ..._buildInlineMetaItems(context, movie, onSeriesTap),
      if (movie.rankings.isNotEmpty)
        MovieDetailSection(
          title: '榜单',
          titleKey: const Key('movie-rankings-title'),
          child: MovieRankingList(rankings: movie.rankings),
        ),
      if (movie.tags.isNotEmpty)
        MovieDetailSection(
          title: '标签',
          child: MovieTagWrap(tags: movie.tags, onTagTap: onTagTap),
        ),
      if (orderedActors.isNotEmpty)
        MovieDetailSection(
          title: '演员',
          child: MovieActorWrap(actors: orderedActors, onActorTap: onActorTap),
        ),
      if (mediaItems.isNotEmpty)
        MovieDetailSection(
          title: '媒体源',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MovieMediaItemList(
                mediaItems: mediaItems,
                selectedMediaId: selectedMediaId,
                onSelect: onMediaSelect,
                isDeletingSelectedMedia: isDeletingSelectedMedia,
                onDeleteSelectedMedia: onDeleteSelectedMedia,
                onOpenPointPreview: onOpenMediaPointPreview,
                onRequestPointMenu: onRequestMediaPointMenu,
              ),
            ],
          ),
        ),
      if (isSubtitlesLoading ||
          subtitleErrorMessage?.trim().isNotEmpty == true ||
          subtitleItems.isNotEmpty)
        MovieDetailSection(
          title: subtitleItems.isEmpty ? '字幕' : '字幕 · ${subtitleItems.length}',
          titleKey: const Key('movie-subtitles-title'),
          child: MovieSubtitleSection(
            items: subtitleItems,
            isLoading: isSubtitlesLoading,
            errorMessage: subtitleErrorMessage,
            onRetry: onRetrySubtitles,
            onOpenSubtitle: onOpenSubtitle,
          ),
        ),
      if (isClipsLoading || clipsErrorMessage != null || clips.isNotEmpty)
        MovieDetailSection(
          title: '切片',
          titleKey: const Key('movie-clips-title'),
          child: MovieClipStrip(
            clips: clips,
            isLoading: isClipsLoading,
            errorMessage: clipsErrorMessage,
            onRetry: onRetryClips,
            onOpenClipActions: onOpenClipActions ?? (_) {},
            onPlayClip: onPlayClip ?? (_) {},
            onRenameClip: onRenameClip ?? (_) {},
            onDeleteClip: onDeleteClip ?? (_) {},
            onAddClipToCollection: onAddClipToCollection ?? (_) {},
          ),
        ),
      if (showSimilarMovies &&
          (isSimilarMoviesLoading ||
              similarMoviesErrorMessage?.trim().isNotEmpty == true ||
              similarMovies.isNotEmpty))
        MovieDetailSection(
          title: '相似影片',
          titleKey: const Key('movie-similar-movies-title'),
          child: MovieSimilarMovieStrip(
            movies: similarMovies,
            isLoading: isSimilarMoviesLoading,
            errorMessage: similarMoviesErrorMessage,
            onRetry: onRetrySimilarMovies,
            onMovieTap: onSimilarMovieTap,
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
        ),
    ];

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(child: header),
        // 正文区块按需构建：详情区块多、每块都带图（剧照 / 演员头像 / 媒体缩略图 /
        // 切片 / 相似影片），急切建整页会让「进入详情页」的第一帧变成几十毫秒的
        // 大帧；交给 [SliverList.builder] 后首帧只建首屏需要的部分，屏幕外的图
        // 也不再提前解析 provider。
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.appSpacing.lg),
          sliver: SliverList.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) => sections[index],
          ),
        ),
      ],
    );
  }
}

List<Widget> _buildInlineMetaItems(
  BuildContext context,
  MovieDetailDto movie,
  VoidCallback? onSeriesTap,
) {
  final items = <_MovieInlineMetaItem>[
    _MovieInlineMetaItem(
      label: '系列',
      value: movie.seriesName.trim(),
      onTap: movie.seriesId == null ? null : onSeriesTap,
    ),
    if (movie.metadataSourceName != null)
      _MovieInlineMetaItem(
        label: '元数据',
        value: movie.javdbId == null
            ? '${movie.metadataSourceName} · 待 JavDB 收录'
            : 'JavDB',
      ),
  ].where((item) => item.value.isNotEmpty).toList(growable: false);

  if (items.isEmpty) {
    return const <Widget>[];
  }

  return <Widget>[
    Padding(
      padding: EdgeInsets.only(
        bottom: context.appComponentTokens.movieDetailSectionGap,
      ),
      child: Column(
        key: const Key('movie-detail-inline-meta-group'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) SizedBox(height: context.appSpacing.sm),
            _MovieInlineMetaRow(item: items[index]),
          ],
        ],
      ),
    ),
  ];
}

class _MovieInlineMetaItem {
  const _MovieInlineMetaItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
}

class _MovieInlineMetaRow extends StatelessWidget {
  const _MovieInlineMetaRow({required this.item});

  final _MovieInlineMetaItem item;

  @override
  Widget build(BuildContext context) {
    final textStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s12,
      weight: AppTextWeight.regular,
      tone: AppTextTone.muted,
    );
    final label = '${item.label} · ${item.value}';
    final onTap = item.onTap;
    if (onTap == null) {
      return Text(label, style: textStyle);
    }

    return Material(
      color: Colors.transparent,
      child: AppInteractiveSurface(
        key: const Key('movie-detail-series-link'),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSpacing.xs,
            vertical: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: textStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: context.appSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: context.appComponentTokens.iconSizeSm,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _resolveViewportHeight(
  BuildContext context,
  BoxConstraints constraints,
) {
  if (constraints.hasBoundedHeight && constraints.maxHeight.isFinite) {
    return constraints.maxHeight;
  }
  return MediaQuery.sizeOf(context).height;
}

/// Hero 前景图的填充方式：**跟随布局宽窄**，而不是跟随平台或页面。
///
/// 宽布局（≥ [MovieDetailInfoBlock.wideBreakpoint]，桌面壳层与平板都是）走
/// [BoxFit.contain]：完整显示不裁切，并启用「信息块压封面下沿」；窄布局
/// （手机、窄窗口）走 [BoxFit.cover]：沉浸全幅铺满裁切。
BoxFit _resolveHeroFit(BoxConstraints constraints) {
  final maxWidth = constraints.maxWidth;
  final isWide =
      !maxWidth.isFinite || maxWidth >= MovieDetailInfoBlock.wideBreakpoint;
  return isWide ? BoxFit.contain : BoxFit.cover;
}

/// Hero 高度。
///
/// 桌面完整显示（`contain`）且有封面时取视口高 × [MovieDetailHeroCard.desktopViewportHeightFactor]；
/// 没有封面时不值得为一块纯色占位撑满一屏，保持固定高度配方。
/// 移动沉浸全幅（`cover`）保持窄屏配方，取宽 × 0.72（260~380，纯照片区）；
/// 宽度无界时退回视口高 × 0.42。
double _resolveHeroHeight(
  BoxConstraints constraints,
  double viewportHeight,
  BoxFit fit, {
  required bool hasCover,
}) {
  final maxWidth = constraints.maxWidth;
  if (maxWidth.isFinite && maxWidth > 0) {
    if (maxWidth >= MovieDetailInfoBlock.wideBreakpoint) {
      if (fit == BoxFit.contain && hasCover) {
        return viewportHeight * MovieDetailHeroCard.desktopViewportHeightFactor;
      }
      return (maxWidth * 0.36).clamp(300.0, 440.0).toDouble();
    }
    return (maxWidth * 0.72).clamp(260.0, 380.0).toDouble();
  }
  return (viewportHeight * 0.42).clamp(260.0, 440.0).toDouble();
}

/// 首屏信息块压在封面下沿的比例（只桌面 / PC）：基数是 Hero 高度。
///
/// 压的位置落在封面的「底部化开带」里：封面在这一带由实到透，压上去的文字底下
/// 只剩一层淡淡的封面颜色（化开带高度 = `Hero高 × 0.28 + 56`），标题和按钮这时
/// 可读，也就不需要额外叠渐变遮罩。取比例而不是固定像素：改
/// [MovieDetailHeroCard.desktopViewportHeightFactor] 时，压的深浅不会跟着变。
///
/// 0.10 ≈ 压在封面下部十分之一处（封面高 490 时约 49px）；调小 → 只把标题
/// 和最上面一排按钮压上去；调大 → 更靠上、压在更实的封面上（要么同时调大
/// [MovieDetailHeroCard.meltBandFactor]，要么叠一层渐变遮罩）；调 0 → 回到
///「信息块在封面下方」的老样子。移动端（沉浸全幅）不叠。
const double _desktopHeroInfoOverlapFactor = 0.10;

/// 见 [_desktopHeroInfoOverlapFactor]。没有封面（骨架 / 该影片无图）时不叠；
/// 上限夹到 Hero 高度，避免比例调大后信息块被提到封面之上。
double _resolveHeroInfoOverlap(
  double heroHeight,
  BoxFit fit, {
  required bool hasCover,
}) {
  if (fit != BoxFit.contain || !hasCover) {
    return 0;
  }
  return (heroHeight * _desktopHeroInfoOverlapFactor).clamp(0.0, heroHeight);
}

/// 压在封面上的标题：番号打头（同行同字号），标题为空或与番号相同时只剩番号。
String _resolveOverlayTitle(MovieDetailDto movie) {
  final number = movie.movieNumber.trim();
  final title = movie.preferredTitle;
  if (title.isEmpty || title == number) {
    return number;
  }
  return '$number $title';
}

/// 标题下的元信息段：评分｜评论数｜想看｜看过｜热度｜上映日期｜时长｜厂商｜导演，
/// 有值的段才出现（零值/空串隐藏）。
List<MovieDetailMetaItem> _resolveMetaItems(
  BuildContext context,
  MovieDetailDto movie,
) {
  final colors = context.appColors;
  return [
    if (movie.score > 0)
      MovieDetailMetaItem(
        icon: Icons.star_outline_rounded,
        iconColor: colors.movieDetailScoreIcon,
        text: movie.score.toStringAsFixed(1),
      ),
    if (movie.commentCount > 0)
      MovieDetailMetaItem(
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: colors.movieDetailCommentCountIcon,
        text: '${movie.commentCount}',
      ),
    if (movie.wantWatchCount > 0)
      MovieDetailMetaItem(text: '想看 · ${movie.wantWatchCount}'),
    if (movie.watchedCount > 0)
      MovieDetailMetaItem(text: '看过 · ${movie.watchedCount}'),
    if (movie.heat > 0)
      MovieDetailMetaItem(
        icon: Icons.local_fire_department_rounded,
        iconColor: colors.movieDetailHeatIcon,
        text: '${movie.heat}',
      ),
    if (movie.releaseDate != null)
      MovieDetailMetaItem(
        text: '上映 · ${DateFormat('yyyy/MM/dd').format(movie.releaseDate!)}',
      ),
    if (movie.durationMinutes > 0)
      MovieDetailMetaItem(
        icon: Icons.schedule_outlined,
        iconColor: colors.movieDetailDurationIcon,
        text: '${movie.durationMinutes} 分钟',
      ),
    if (movie.makerName.trim().isNotEmpty)
      MovieDetailMetaItem(text: '厂商 · ${movie.makerName.trim()}'),
    if (movie.directorName.trim().isNotEmpty)
      MovieDetailMetaItem(text: '导演 · ${movie.directorName.trim()}'),
  ];
}

/// 右列文件大小：选中媒体的文件大小，无选中/大小为 0 时不显示。
String? _resolveFileSizeLabel(
  List<MovieMediaItemDto> mediaItems,
  int? selectedMediaId,
) {
  if (selectedMediaId == null) return null;
  for (final item in mediaItems) {
    if (item.mediaId == selectedMediaId) {
      return item.fileSizeBytes > 0 ? formatFileSize(item.fileSizeBytes) : null;
    }
  }
  return null;
}

/// 整页模糊背景：封面高斯模糊铺底 + 底色罩一层。
/// 配方引用 [MovieDetailVeil]，与 Hero 底座严格同值，底边相接无分割。
///
/// 无封面时退回纯底色，保证加载态/空态不断层。
class _MovieDetailBackground extends StatelessWidget {
  const _MovieDetailBackground({required this.url, required this.baseColor});

  final String? url;

  /// 桌面传 surfaceElevated、移动传 surfaceCard：遮罩底色跟随各自主题。
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return ColoredBox(color: baseColor);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // 模糊会在边缘留下透明回透，放大一圈推出可视区。
        Transform.scale(
          scale: MovieDetailVeil.backgroundScale,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: MovieDetailVeil.backgroundBlurSigma,
              sigmaY: MovieDetailVeil.backgroundBlurSigma,
            ),
            child: MaskedImage(
              url: url!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              // 占位与回退底色同色；解码完成后直接显示（罩了重 veil，不再单独淡入，
              // 避免与前景图两次先后闪烁）。
              placeholderColor: baseColor,
              animateReveal: false,
            ),
          ),
        ),
        ColoredBox(
          color: baseColor.withValues(
            alpha: MovieDetailVeil.veilAlphaFor(Theme.of(context).brightness),
          ),
        ),
      ],
    );
  }
}

class MovieDetailErrorState extends StatelessWidget {
  const MovieDetailErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppEmptyState(message: message),
        SizedBox(height: context.appSpacing.lg),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}
