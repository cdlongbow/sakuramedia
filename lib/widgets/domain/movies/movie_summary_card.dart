import 'dart:async';
import 'dart:ui' as ui;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/platform/haptic_feedback.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_inspector_launcher.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_playback_launcher.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_cover_hover_info.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_cover_card.dart';
import 'package:sakuramedia/widgets/base/media/images/app_cover_bottom_shade.dart';
import 'package:sakuramedia/widgets/base/media/images/app_image_action_trigger.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';
import 'package:sakuramedia/widgets/domain/movies/subscription_heart_badge.dart';

/// 影片摘要卡：整卡即封面，与全站封面卡片共用同一套悬停披露范式。
///
/// - 收起态：番号（+ 推荐理由）、排名徽标与 ⓘ 压在底部渐变上常显；触摸端没有
///   hover，停留在这层；
/// - 桌面悬停：底部渐显压暗层（180ms ease-out），标题/时长/日期与整行动作
///   （播放 / 订阅 / 标记合集-单体 / 屏蔽影片）淡入，收起态主键层淡出；系统开启
///   「减弱动态效果」时退化为瞬时切换；
/// - 参数与全站封面卡一致：`lg` 圆角、`surfaceCard` 底色、常驻 1px 边框与常驻
///   卡片阴影；按下反馈与 [AppInteractiveSurface] 一致（整体变淡 0.7）。
///
/// 右端的 ⓘ 打开详情检查器（评论 / 磁力 / 缩略图；桌面弹对话框、移动弹底部抽屉），
/// 点击后先取一次影片详情以带出默认媒体；右键与长按仍打开影片操作菜单。
class MovieSummaryCard extends StatefulWidget {
  const MovieSummaryCard({
    super.key,
    required this.movie,
    this.showStatusBadges = true,
    this.rank,
    this.secondaryLabel,
    this.onTap,
    this.onRequestMenu,
    this.onSubscriptionTap,
    this.onToggleCollectionType,
    this.onBlacklist,
    this.isSubscriptionUpdating = false,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectedChanged,
  });

  final MovieListItemDto movie;
  final bool showStatusBadges;
  final int? rank;
  final String? secondaryLabel;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onRequestMenu;
  final VoidCallback? onSubscriptionTap;

  /// 悬停动作行的「标记为合集 / 单体」；为 `null` 时不显示该按钮。
  final VoidCallback? onToggleCollectionType;

  /// 悬停动作行的「屏蔽影片」；为 `null` 或影片已订阅（不可屏蔽）时不显示。
  final VoidCallback? onBlacklist;
  final bool isSubscriptionUpdating;

  /// 选择模式开关：为 true 时卡片进入多选态——外圈换选中描边、叠勾选徽标、
  /// 屏蔽 [onRequestMenu] / [onSubscriptionTap]，点击整卡切换选中。
  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectedChanged;

  @override
  State<MovieSummaryCard> createState() => _MovieSummaryCardState();
}

class _MovieSummaryCardState extends State<MovieSummaryCard> {
  bool _inspectorLoading = false;

  MovieListItemDto get movie => widget.movie;

  /// 先取默认媒体让缩略图页签可用（取不到也能开），再按平台弹出弹窗。
  Future<void> _openInspector() async {
    if (_inspectorLoading) {
      return;
    }
    setState(() => _inspectorLoading = true);
    final media = await fetchDefaultInspectorMedia(
      context,
      movieNumber: movie.movieNumber,
    );
    if (!mounted) {
      return;
    }
    setState(() => _inspectorLoading = false);
    showMovieInspector(
      context,
      movieNumber: movie.movieNumber,
      selectedMedia: media,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final componentTokens = context.appComponentTokens;
    final spacing = context.appSpacing;
    final handlesSubscriptionTapAtCardLevel =
        !widget.selectionMode &&
        widget.onSubscriptionTap != null &&
        (widget.onTap != null || widget.onRequestMenu != null);
    final showCluster = widget.showStatusBadges && !widget.selectionMode;
    final showHeat = widget.showStatusBadges && movie.heat > 0;

    final card = AppCoverCard(
      key: Key('movie-summary-card-${movie.movieNumber}'),
      coverAspectRatio: componentTokens.movieCardAspectRatio,
      hoverEnabled: !widget.selectionMode,
      selectionMode: widget.selectionMode,
      isSelected: widget.isSelected,
      cover: _MovieCover(
        movieNumber: movie.movieNumber,
        thinCoverImage: movie.thinCoverImage,
        coverImage: movie.coverImage,
      ),
      collapsedOverlay: _buildCollapsedOverlay(context),
      infoBuilder: (context) => _buildHoverInfo(context),
      overlaysBuilder: (context, constraints) {
        final wrapHeat =
            showHeat && _shouldWrapHeat(context, constraints.maxWidth);
        return [
          // 选择模式下屏蔽订阅心/播放态角标，避免手势冲突与信息噪音。
          if (showCluster)
            Positioned(
              top: spacing.xs,
              left: spacing.xs,
              child: Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: [
                  IgnorePointer(
                    ignoring: handlesSubscriptionTapAtCardLevel,
                    child: SubscriptionHeartBadge(
                      key: Key(
                        'movie-summary-card-subscription-${movie.movieNumber}',
                      ),
                      loadingKey: Key(
                        'movie-summary-card-subscription-loading-${movie.movieNumber}',
                      ),
                      isSubscribed: movie.isSubscribed,
                      isUpdating: widget.isSubscriptionUpdating,
                      onTap: handlesSubscriptionTapAtCardLevel
                          ? null
                          : widget.onSubscriptionTap,
                    ),
                  ),
                  if (movie.canPlay)
                    _StatusBadge(
                      key: Key(
                        'movie-summary-card-status-playable-${movie.movieNumber}',
                      ),
                      icon: Icons.play_arrow_rounded,
                      iconColor: context.appTextPalette.onMedia,
                      background: colors.movieCardPlayableBadgeBackground,
                    ),
                  if (movie.maxMediaWidth >= 3840)
                    _ResolutionBadge(
                      movie: movie,
                      movieNumber: movie.movieNumber,
                    ),
                ],
              ),
            ),
          // 卡片放不下时热度折到下一行，避免压住左上角角标。
          if (showHeat)
            Positioned(
              top: wrapHeat
                  ? spacing.xs * 2 + componentTokens.movieCardStatusBadgeSize
                  : spacing.xs,
              left: wrapHeat ? spacing.xs : null,
              right: wrapHeat ? null : spacing.xs,
              child: _HeatBadge(
                movieNumber: movie.movieNumber,
                heat: movie.heat,
              ),
            ),
        ];
      },
    );

    if (widget.selectionMode) {
      return AppInteractiveSurface(
        key: Key('movie-summary-card-checkbox-${movie.movieNumber}'),
        enabled: widget.onSelectedChanged != null,
        onTap: () => widget.onSelectedChanged?.call(!widget.isSelected),
        child: card,
      );
    }
    if (widget.onTap == null && widget.onRequestMenu == null) {
      return card;
    }
    return AppImageActionTrigger(
      onTap: handlesSubscriptionTapAtCardLevel ? null : widget.onTap,
      onTapAt: handlesSubscriptionTapAtCardLevel
          ? (localPosition) {
              final hitPadding =
                  (componentTokens.subscriptionHeartHitSize -
                      componentTokens.movieCardStatusBadgeSize) /
                  2;
              final hitExtent =
                  spacing.xs +
                  componentTokens.movieCardStatusBadgeSize +
                  hitPadding;
              if (localPosition.dx <= hitExtent &&
                  localPosition.dy <= hitExtent) {
                if (!widget.isSubscriptionUpdating) {
                  triggerSelectionHaptic();
                  widget.onSubscriptionTap!();
                }
              } else {
                widget.onTap?.call();
              }
            }
          : null,
      onRequestMenu: widget.onRequestMenu,
      child: card,
    );
  }

  /// 收起态主键层：番号（+ 推荐理由）、排名徽标与 ⓘ 压在底部渐变上常显；
  /// 悬停展开时由 [AppCoverHoverInfo] 淡出，信息在悬停面板里继续提供。
  Widget _buildCollapsedOverlay(BuildContext context) {
    final spacing = context.appSpacing;
    final number = Text(
      movie.movieNumber,
      key: Key('movie-summary-card-number-${movie.movieNumber}'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: resolveCoverOverlayTextStyle(
        context,
        size: AppTextSize.s12,
        weight: AppTextWeight.semibold,
      ),
    );
    final Widget info;
    // 推荐理由（如「热门：某某女优」）在触摸端没有悬停可触发，常显为第二行，
    // 否则移动端会彻底看不到它。
    if (widget.secondaryLabel case final label?) {
      info = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          number,
          SizedBox(height: spacing.xs / 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: resolveCoverOverlayTextStyle(
              context,
              size: AppTextSize.s10,
              opacity: 0.72,
            ),
          ),
        ],
      );
    } else {
      info = number;
    }
    final rank = widget.rank;
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppCoverBottomShade(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.sm,
              spacing.md,
              spacing.sm + spacing.xs / 2,
            ),
            child: Row(
              children: [
                Expanded(child: info),
                if (rank != null) ...[
                  SizedBox(width: spacing.sm),
                  _RankBadge(rank: rank, movieNumber: movie.movieNumber),
                ],
                if (!widget.selectionMode) ...[
                  SizedBox(width: spacing.xs),
                  _CardInfoButton(
                    movieNumber: movie.movieNumber,
                    isLoading: _inspectorLoading,
                    onTap: () => unawaited(_openInspector()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 悬停面板：番号 + 推荐理由、标题（两行）、时长·日期与整行动作按钮，
  /// 行尾保留排名徽标与 ⓘ；与全站封面卡片共用同一套底部披露层。
  Widget _buildHoverInfo(BuildContext context) {
    final spacing = context.appSpacing;
    final showBadges = widget.showStatusBadges && !widget.selectionMode;
    final actions = <Widget>[
      // 播放是这一层的主操作，用白底实心；选择模式与不可播放时不出。
      if (showBadges && movie.canPlay)
        AppCoverHoverActionButton(
          key: Key('movie-summary-card-play-${movie.movieNumber}'),
          icon: Icons.play_arrow_rounded,
          primary: true,
          tooltip: '播放',
          onTap: () => _handlePlay(context),
        ),
      if (widget.onSubscriptionTap != null)
        AppCoverHoverActionButton(
          key: Key(
            'movie-summary-card-subscription-action-${movie.movieNumber}',
          ),
          icon: movie.isSubscribed
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: movie.isSubscribed ? '取消订阅' : '订阅影片',
          onTap: widget.isSubscriptionUpdating
              ? null
              : widget.onSubscriptionTap,
        ),
      if (widget.onToggleCollectionType != null)
        AppCoverHoverActionButton(
          key: Key('movie-summary-card-collection-type-${movie.movieNumber}'),
          icon: Icons.category_outlined,
          tooltip: '标记为合集/单体',
          onTap: widget.onToggleCollectionType,
        ),
      // 已订阅影片不可屏蔽，与右键菜单的显隐规则一致。
      if (widget.onBlacklist != null && !movie.isSubscribed)
        AppCoverHoverActionButton(
          key: Key('movie-summary-card-blacklist-${movie.movieNumber}'),
          icon: Icons.block_rounded,
          tooltip: '屏蔽影片',
          onTap: widget.onBlacklist,
        ),
    ];
    final rank = widget.rank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          movie.movieNumber,
          key: Key('movie-summary-card-number-${movie.movieNumber}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: resolveCoverOverlayTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.semibold,
          ),
        ),
        if (widget.secondaryLabel case final label?) ...[
          SizedBox(height: spacing.xs / 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: resolveCoverOverlayTextStyle(
              context,
              size: AppTextSize.s10,
              opacity: 0.72,
            ),
          ),
        ],
        SizedBox(height: spacing.xs / 2),
        Text(
          movie.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: resolveCoverOverlayTextStyle(
            context,
            size: AppTextSize.s12,
            opacity: 0.78,
          ),
        ),
        SizedBox(height: spacing.xs),
        Text(
          _metaLine(movie),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: resolveCoverOverlayTextStyle(
            context,
            size: AppTextSize.s10,
            opacity: 0.64,
          ),
        ),
        SizedBox(height: spacing.sm),
        // 动作独占一行：4 个动作 + 排名 + 信息按钮挤在一行会在标准卡宽
        // （movieCardTargetWidth 220）折行，排名与信息按钮独立成行后动作始终单行。
        AppCoverHoverActionBar(actions: actions),
        if (actions.isNotEmpty) SizedBox(height: spacing.xs),
        Row(
          children: [
            const Spacer(),
            if (rank != null) ...[
              _RankBadge(rank: rank, movieNumber: movie.movieNumber),
              SizedBox(width: spacing.xs),
            ],
            _CardInfoButton(
              movieNumber: movie.movieNumber,
              isLoading: _inspectorLoading,
              onTap: () => unawaited(_openInspector()),
            ),
          ],
        ),
      ],
    );
  }

  /// 顶部一行放不下左上角角标与右上角热度时，热度折到下一行。
  bool _shouldWrapHeat(BuildContext context, double cardWidth) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final heatText = TextPainter(
      text: TextSpan(
        text: _formatMovieHeat(movie.heat),
        style: _onMediaStyle(context, size: AppTextSize.s10),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final heatWidth =
        spacing.sm * 2 + tokens.iconSizeXs + spacing.xs + heatText.width + 2;
    heatText.dispose();
    final statusWidth =
        tokens.movieCardStatusBadgeSize +
        (!widget.selectionMode && movie.canPlay
            ? spacing.xs + tokens.movieCardStatusBadgeSize
            : 0) +
        (!widget.selectionMode && movie.maxMediaWidth >= 3840
            ? spacing.xs + spacing.sm + tokens.movieCardStatusBadgeSize
            : 0);
    return statusWidth + heatWidth + spacing.xs * 3 > cardWidth;
  }

  /// 播放：走统一播放入口，并把当前路由作为应用内播放页的返回落点。
  void _handlePlay(BuildContext context) {
    unawaited(
      launchMoviePlayback(
        context,
        movieNumber: movie.movieNumber,
        inAppFallbackPath: _currentLocationOrNull(context),
      ),
    );
  }

  /// 应用内播放页的返回落点：当前路由。拿不到路由（部分 widget 测试）时返回 null，
  /// [launchMoviePlayback] 会退回到该影片的详情页。
  String? _currentLocationOrNull(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.toString();
    } on Object {
      return null;
    }
  }
}

/// 卡片信息行右端的详情检查器入口：常显，点击打开评论 / 磁力 / 缩略图弹窗。
class _CardInfoButton extends StatelessWidget {
  const _CardInfoButton({
    required this.movieNumber,
    required this.isLoading,
    required this.onTap,
  });

  final String movieNumber;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tokens = context.appComponentTokens;
    final size = tokens.movieCardStatusBadgeSize;
    return GestureDetector(
      key: Key('movie-summary-card-inspector-$movieNumber'),
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: MouseRegion(
        cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.mediaOverlayStrong,
            borderRadius: context.appRadius.pillBorder,
            border: Border.all(
              color: colors.borderSubtle.withValues(alpha: 0.42),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: tokens.iconSize3xs,
                  height: tokens.iconSize3xs,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.appTextPalette.onMedia,
                  ),
                )
              : Icon(
                  Icons.info_outline_rounded,
                  size: tokens.iconSizeXs,
                  color: context.appTextPalette.onMedia,
                ),
        ),
      ),
    );
  }
}

/// 清晰度胶囊：毛玻璃底 + 4K/8K 粗体字，与订阅心、播放标同排。
class _ResolutionBadge extends StatelessWidget {
  const _ResolutionBadge({required this.movie, required this.movieNumber});

  final MovieListItemDto movie;
  final String movieNumber;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final componentTokens = context.appComponentTokens;
    final spacing = context.appSpacing;
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: context.appRadius.pillBorder,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: spacing.xs, sigmaY: spacing.xs),
          child: Container(
            key: Key('movie-summary-card-resolution-$movieNumber'),
            width: componentTokens.movieCardStatusBadgeSize + spacing.sm,
            height: componentTokens.movieCardStatusBadgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.mediaOverlayStrong,
              borderRadius: context.appRadius.pillBorder,
              border: Border.all(
                color: colors.borderSubtle.withValues(alpha: 0.42),
              ),
            ),
            child: Text(
              movie.maxMediaWidth >= 7680 ? '8K' : '4K',
              style:
                  resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.semibold,
                    tone: AppTextTone.onMedia,
                  ).copyWith(
                    color: context.appTextPalette.onMedia,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 右上角热度胶囊：火焰图标 + 格式化数值。
class _HeatBadge extends StatelessWidget {
  const _HeatBadge({required this.movieNumber, required this.heat});

  final String movieNumber;
  final int heat;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    return Container(
      key: Key('movie-summary-card-heat-$movieNumber'),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.mediaOverlayStrong,
        borderRadius: context.appRadius.pillBorder,
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: context.appComponentTokens.iconSizeXs,
            color: colors.movieDetailHeatIcon,
          ),
          SizedBox(width: spacing.xs),
          Text(
            _formatMovieHeat(heat),
            key: Key('movie-summary-card-heat-text-$movieNumber'),
            style: _onMediaStyle(context, size: AppTextSize.s10),
          ),
        ],
      ),
    );
  }
}

/// 圆底状态角标（当前只用于可播放标记）。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final componentTokens = context.appComponentTokens;

    return Container(
      width: componentTokens.movieCardStatusBadgeSize,
      height: componentTokens.movieCardStatusBadgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: context.appRadius.pillBorder,
      ),
      child: Icon(icon, size: componentTokens.iconSizeXl, color: iconColor),
    );
  }
}

/// 封面 / 信息条上的文字：onMedia 白色 + macOS 文本样式的行高与字距。
TextStyle _onMediaStyle(
  BuildContext context, {
  required AppTextSize size,
  AppTextWeight weight = AppTextWeight.regular,
}) {
  return switch (size) {
    AppTextSize.s12 => resolveAppTextStyle(
      context,
      size: size,
      weight: weight,
      tone: AppTextTone.onMedia,
      height: 16 / 13,
      letterSpacing: -0.08,
    ),
    AppTextSize.s10 => resolveAppTextStyle(
      context,
      size: size,
      weight: weight,
      tone: AppTextTone.onMedia,
      height: 13 / 10,
      letterSpacing: 0.12,
    ),
    _ => resolveAppTextStyle(
      context,
      size: size,
      weight: weight,
      tone: AppTextTone.onMedia,
    ),
  };
}

String _metaLine(MovieListItemDto movie) {
  final date = movie.releaseDate;
  final datePart = date == null
      ? ''
      : '${date.year}.${date.month.toString().padLeft(2, '0')}.'
            '${date.day.toString().padLeft(2, '0')}';
  if (datePart.isEmpty) {
    return '${movie.durationMinutes} 分钟';
  }
  return '${movie.durationMinutes} 分钟 · $datePart';
}

String _formatMovieHeat(int heat) {
  if (heat < 1000) {
    return '$heat';
  }

  final valueInK = heat / 1000;
  final fixed = valueInK.toStringAsFixed(1);
  final trimmed = fixed.endsWith('.0')
      ? fixed.substring(0, fixed.length - 2)
      : fixed;
  return '${trimmed}k';
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.movieNumber});

  final int rank;
  final String movieNumber;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      key: Key('movie-summary-card-rank-$movieNumber'),
      padding: EdgeInsets.symmetric(
        horizontal: context.appSpacing.sm,
        vertical: context.appSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.mediaOverlayStrong,
        borderRadius: context.appRadius.pillBorder,
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.42)),
      ),
      child: Text(
        '#$rank',
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s10,
          weight: AppTextWeight.regular,
          tone: AppTextTone.onMedia,
        ),
      ),
    );
  }
}

/// 封面按「图源 + 番号」择优渲染:FC2- 番号用主封面 + [BoxFit.contain](其封面多为横图,
/// cover 会裁切);其余优先用瘦封面(竖图,默认 cover 铺满),无瘦封面再退主封面 + contain;
/// 都缺失则渲染占位渐变。
class _MovieCover extends StatelessWidget {
  const _MovieCover({
    required this.movieNumber,
    required this.thinCoverImage,
    required this.coverImage,
  });

  final String movieNumber;
  final MovieImageDto? thinCoverImage;
  final MovieImageDto? coverImage;

  @override
  Widget build(BuildContext context) {
    final thinCoverUrl = _resolveMovieImageUrl(thinCoverImage);
    final coverUrl = _resolveMovieImageUrl(coverImage);

    // FC2- 番号统一用主封面 + contain 完整展示(其封面多为横图,cover 会裁切)。
    if (movieNumber.startsWith('FC2-') && coverUrl != null) {
      return MaskedImage(url: coverUrl, fit: BoxFit.contain);
    }

    if (thinCoverUrl != null) {
      return MaskedImage(url: thinCoverUrl);
    }

    if (coverUrl != null) {
      return MaskedImage(url: coverUrl, fit: BoxFit.contain);
    }

    // 纯图片卡缺图态统一为 muted 纯色块：不带渐变 / 居中图标。
    return ColoredBox(
      key: Key('movie-summary-card-placeholder-$movieNumber'),
      color: context.appColors.surfaceMuted,
    );
  }
}

String? _resolveMovieImageUrl(MovieImageDto? image) {
  final url = image?.bestAvailableUrl.trim();
  if (url == null || url.isEmpty) {
    return null;
  }
  return url;
}
