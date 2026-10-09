import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';

/// 影片详情照片下方的标题操作信息块：标题全宽在上，
/// 下方宽屏左右双列（左操作 / 右信息）、窄屏上下堆叠。
/// 坐在浅色模糊背景上，文字走深色系（与压图的白色系区分）。
class MovieDetailInfoBlock extends StatelessWidget {
  const MovieDetailInfoBlock({
    super.key,
    required this.isSubscribed,
    this.overlayTitle,
    this.metaItems = const <MovieDetailMetaItem>[],
    this.fileSizeLabel,
    this.watchLabel,
    this.watchTooltip,
    this.onPlayTap,
    this.isPlayLoading = false,
    this.onSubscriptionTap,
    this.isSubscriptionUpdating = false,
    this.onPlaylistTap,
    this.playlistTooltip = '播放列表',
    this.onMoreActionsTap,
    this.isMoreActionsUpdating = false,
    this.mergePlaybackLabel,
    this.onMergePlaybackTap,
    this.isMergePlaybackLoading = false,
  });

  final bool isSubscribed;

  /// 全宽标题（番号打头，为 null/空时不显示）。
  final String? overlayTitle;

  /// 标题下的元信息段（评分｜评论｜想看｜看过｜热度｜厂商｜导演），
  /// 为空时整行不显示。
  final List<MovieDetailMetaItem> metaItems;

  /// 选中媒体的文件大小（如 20.99 GB），为 null/空时不显示。
  final String? fileSizeLabel;

  final String? watchLabel;
  final String? watchTooltip;

  final VoidCallback? onPlayTap;

  /// 播放动作进行中（如合并播放探测/拉起外部播放器），按钮显示 loading 并禁用。
  final bool isPlayLoading;

  final VoidCallback? onSubscriptionTap;
  final bool isSubscriptionUpdating;
  final VoidCallback? onPlaylistTap;

  /// 播放列表键的无障碍提示（加入/管理），默认“播放列表”。
  final String playlistTooltip;
  final Future<void> Function(Offset globalPosition)? onMoreActionsTap;
  final bool isMoreActionsUpdating;

  /// 合并播放次入口（多段媒体才有），为 null/空时不显示。
  final String? mergePlaybackLabel;
  final VoidCallback? onMergePlaybackTap;
  final bool isMergePlaybackLoading;

  /// 宽窄屏分界：以下走上下堆叠，以上走左右双列。
  static const double wideBreakpoint = 600;

  /// 左操作列固定宽。
  static const double actionsColumnWidth = 200;

  /// 操作列是否值得出现：播放/合并之外的三键（订阅/列表/更多）只要回调在就保留，
  /// 不可播时也不整体消失。判定放在 [_InfoActionsColumn.isVisible]，父级与自身共用。

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final info = _heroInfo;
    final hasInfo = !info.isEmpty;
    final actions = _InfoActionsColumn(
      onPlayTap: onPlayTap,
      isPlayLoading: isPlayLoading,
      isSubscribed: isSubscribed,
      onSubscriptionTap: onSubscriptionTap,
      isSubscriptionUpdating: isSubscriptionUpdating,
      onPlaylistTap: onPlaylistTap,
      playlistTooltip: playlistTooltip,
      onMoreActionsTap: onMoreActionsTap,
      isMoreActionsUpdating: isMoreActionsUpdating,
      mergePlaybackLabel: mergePlaybackLabel,
      onMergePlaybackTap: onMergePlaybackTap,
      isMergePlaybackLoading: isMergePlaybackLoading,
    );
    final hasActions = actions.isVisible;
    final title = overlayTitle?.trim() ?? '';
    if (title.isEmpty && !hasInfo && !hasActions) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              key: const Key('movie-detail-hero-overlay-title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s18,
                weight: AppTextWeight.semibold,
                tone: AppTextTone.primary,
              ),
            ),
          if (hasInfo || hasActions) ...[
            SizedBox(height: spacing.xs),
            if (MediaQuery.sizeOf(context).width >= wideBreakpoint)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasActions) ...[
                    SizedBox(width: actionsColumnWidth, child: actions),
                    SizedBox(width: spacing.md),
                  ],
                  Expanded(child: _InfoColumn(info: info)),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoColumn(info: info),
                  if (hasInfo) SizedBox(height: spacing.sm),
                  if (hasActions) actions,
                ],
              ),
          ],
        ],
      ),
    );
  }

  _HeroInfo get _heroInfo => _HeroInfo(
    metaItems: metaItems,
    fileSizeLabel: fileSizeLabel?.trim().isNotEmpty == true
        ? fileSizeLabel!.trim()
        : null,
    watchLabel: watchLabel,
    watchTooltip: watchTooltip ?? watchLabel,
  );
}

/// 元信息段：有合适图标的用图标 + 数值（如评分/热度），没有的用文字
///（如 `厂商 · DAHLIA`）。
class MovieDetailMetaItem {
  const MovieDetailMetaItem({this.icon, this.iconColor, required this.text});

  final IconData? icon;
  final Color? iconColor;
  final String text;
}

/// 右信息列的数据快照，避免 Column/Row 两处重复判空。
class _HeroInfo {
  const _HeroInfo({
    this.metaItems = const <MovieDetailMetaItem>[],
    this.fileSizeLabel,
    this.watchLabel,
    this.watchTooltip,
  });

  final List<MovieDetailMetaItem> metaItems;
  final String? fileSizeLabel;
  final String? watchLabel;
  final String? watchTooltip;

  bool get isEmpty =>
      metaItems.isEmpty && fileSizeLabel == null && watchLabel == null;
}

/// 元信息段：图标（有的话）+ 数值/文字，单行内不换行。
class _MetaSegment extends StatelessWidget {
  const _MetaSegment({required this.item});

  final MovieDetailMetaItem item;

  @override
  Widget build(BuildContext context) {
    final icon = item.icon;
    if (icon == null) {
      return Text(
        item.text,
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          weight: AppTextWeight.regular,
          tone: AppTextTone.secondary,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: context.appComponentTokens.iconSizeXs,
          color: item.iconColor ?? context.appTextPalette.secondary,
        ),
        SizedBox(width: context.appSpacing.xs),
        Text(
          item.text,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.regular,
            tone: AppTextTone.secondary,
          ),
        ),
      ],
    );
  }
}

/// 右信息列：深色字（坐浅底）。
class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.info});

  final _HeroInfo info;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    if (info.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.metaItems.isNotEmpty)
          Wrap(
            key: const Key('movie-detail-hero-overlay-meta'),
            spacing: context.appSpacing.sm,
            runSpacing: context.appSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var index = 0; index < info.metaItems.length; index++) ...[
                if (index > 0)
                  Text(
                    '｜',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.muted,
                    ),
                  ),
                _MetaSegment(item: info.metaItems[index]),
              ],
            ],
          ),
        if (info.fileSizeLabel != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            info.fileSizeLabel!,
            key: const Key('movie-detail-hero-overlay-size'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.regular,
              tone: AppTextTone.secondary,
            ),
          ),
        ],
        if (info.watchLabel != null) ...[
          SizedBox(height: spacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: info.watchTooltip ?? info.watchLabel!,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.sm,
                  vertical: spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.mediaOverlayStrong,
                  borderRadius: context.appRadius.smBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: context.appComponentTokens.iconSizeXs,
                      color: context.appTextPalette.onMedia,
                    ),
                    SizedBox(width: spacing.xs),
                    Flexible(
                      child: Text(
                        info.watchLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          tone: AppTextTone.onMedia,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 左操作列：白色分体播放键（左播放 / 右合并，五五开）+ 订阅/播放列表/更多三键。
class _InfoActionsColumn extends StatelessWidget {
  const _InfoActionsColumn({
    required this.onPlayTap,
    required this.isPlayLoading,
    required this.isSubscribed,
    required this.onSubscriptionTap,
    required this.isSubscriptionUpdating,
    required this.onPlaylistTap,
    required this.playlistTooltip,
    required this.onMoreActionsTap,
    required this.isMoreActionsUpdating,
    required this.mergePlaybackLabel,
    required this.onMergePlaybackTap,
    required this.isMergePlaybackLoading,
  });

  final VoidCallback? onPlayTap;
  final bool isPlayLoading;
  final bool isSubscribed;
  final VoidCallback? onSubscriptionTap;
  final bool isSubscriptionUpdating;
  final VoidCallback? onPlaylistTap;
  final String playlistTooltip;
  final Future<void> Function(Offset globalPosition)? onMoreActionsTap;
  final bool isMoreActionsUpdating;
  final String? mergePlaybackLabel;
  final VoidCallback? onMergePlaybackTap;
  final bool isMergePlaybackLoading;

  bool get _hasMerge => mergePlaybackLabel?.trim().isNotEmpty == true;

  /// 是否有任何可渲染的操作键；父级用它决定是否给操作列留位。
  bool get isVisible =>
      onPlayTap != null ||
      isPlayLoading ||
      _hasMerge ||
      onSubscriptionTap != null ||
      isSubscriptionUpdating ||
      onPlaylistTap != null ||
      onMoreActionsTap != null ||
      isMoreActionsUpdating;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onPlayTap != null || isPlayLoading || _hasMerge)
          _InfoSplitPlayButton(
            onPlayTap: isPlayLoading ? null : onPlayTap,
            isPlayLoading: isPlayLoading,
            hasMerge: _hasMerge,
            mergeTooltip: _hasMerge ? mergePlaybackLabel!.trim() : '',
            onMergeTap: isMergePlaybackLoading ? null : onMergePlaybackTap,
            isMergeLoading: isMergePlaybackLoading,
          ),
        SizedBox(height: spacing.xs),
        Row(
          children: [
            Expanded(
              child: _InfoActionKey(
                key: const Key('movie-detail-hero-subscription-icon'),
                tooltip: isSubscribed ? '已订阅' : '订阅',
                onTap: isSubscriptionUpdating ? null : onSubscriptionTap,
                child: isSubscriptionUpdating
                    ? SizedBox(
                        key: const Key(
                          'movie-detail-hero-subscription-loading',
                        ),
                        width: context.appComponentTokens.iconSizeSm,
                        height: context.appComponentTokens.iconSizeSm,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color?>(
                            context.appTextPalette.secondary,
                          ),
                        ),
                      )
                    : Icon(
                        isSubscribed
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: context.appComponentTokens.iconSizeSm,
                        color: isSubscribed
                            ? context.appColors.subscriptionHeartIcon
                            : context.appTextPalette.secondary,
                      ),
              ),
            ),
            SizedBox(width: spacing.xs),
            Expanded(
              child: _InfoActionKey(
                key: const Key('movie-detail-playlist-trigger'),
                tooltip: playlistTooltip,
                onTap: onPlaylistTap,
                child: Icon(
                  Icons.playlist_add_rounded,
                  size: context.appComponentTokens.iconSizeSm,
                  color: context.appTextPalette.secondary,
                ),
              ),
            ),
            SizedBox(width: spacing.xs),
            Expanded(
              child: _InfoMoreKey(
                isUpdating: isMoreActionsUpdating,
                onTap: onMoreActionsTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 白色分体播放键：左右五五开（左播放 / 右合并），浅底上加细边框保可读。
class _InfoSplitPlayButton extends StatelessWidget {
  const _InfoSplitPlayButton({
    required this.onPlayTap,
    required this.isPlayLoading,
    required this.hasMerge,
    required this.mergeTooltip,
    required this.onMergeTap,
    required this.isMergeLoading,
  });

  final VoidCallback? onPlayTap;
  final bool isPlayLoading;
  final bool hasMerge;
  final String mergeTooltip;
  final VoidCallback? onMergeTap;
  final bool isMergeLoading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appComponentTokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: tokens.buttonHeightMd,
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard.withValues(alpha: 0.82),
        borderRadius: context.appRadius.pillBorder,
        border: Border.all(color: context.appColors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppInteractiveSurface(
              enabled: onPlayTap != null,
              key: const Key('movie-detail-hero-play-button'),
              onTap: onPlayTap,
              child: Container(
                height: tokens.buttonHeightMd,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.buttonHorizontalPaddingMd,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPlayLoading)
                      SizedBox(
                        width: tokens.iconSizeSm,
                        height: tokens.iconSizeSm,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color?>(primary),
                        ),
                      )
                    else ...[
                      Icon(
                        Icons.play_arrow_rounded,
                        size: tokens.iconSizeSm,
                        color: primary,
                      ),
                      SizedBox(width: tokens.buttonGapMd),
                      Text(
                        '播放',
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s14,
                          weight: AppTextWeight.medium,
                          tone: AppTextTone.primary,
                        ).copyWith(color: primary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (hasMerge) ...[
            SizedBox(
              width: 1,
              height: tokens.iconSizeSm,
              child: ColoredBox(
                color: primary.withValues(alpha: 0.25),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: mergeTooltip,
                child: AppInteractiveSurface(
                  enabled: onMergeTap != null,
                  key: const Key('movie-detail-merge-playback-button'),
                  onTap: onMergeTap,
                  child: SizedBox(
                    height: tokens.buttonHeightMd,
                    child: Center(
                      child: isMergeLoading
                          ? SizedBox(
                              width: tokens.iconSizeXs,
                              height: tokens.iconSizeXs,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color?>(
                                  primary,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.merge_rounded,
                                  size: tokens.iconSizeSm,
                                  color: primary,
                                ),
                                SizedBox(width: tokens.buttonGapMd),
                                Text(
                                  '合并',
                                  style: resolveAppTextStyle(
                                    context,
                                    size: AppTextSize.s14,
                                    weight: AppTextWeight.medium,
                                    tone: AppTextTone.primary,
                                  ).copyWith(color: primary),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 中性小操作键（订阅 / 播放列表）：浅底 + 深色图标。
class _InfoActionKey extends StatelessWidget {
  const _InfoActionKey({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AppInteractiveSurface(
        enabled: onTap != null,
        onTap: onTap,
        child: Container(
          height: context.appComponentTokens.buttonHeightMd,
          decoration: BoxDecoration(
            color: context.appColors.surfaceMuted,
            borderRadius: context.appRadius.mdBorder,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// 更多操作键：需要点击位置弹菜单，用 onTapDown 接。
class _InfoMoreKey extends StatelessWidget {
  const _InfoMoreKey({required this.isUpdating, required this.onTap});

  final bool isUpdating;
  final Future<void> Function(Offset globalPosition)? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appComponentTokens;
    final button = Container(
      key: const Key('movie-detail-hero-more-actions-button'),
      height: tokens.buttonHeightMd,
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.mdBorder,
      ),
      child: Center(
        child: isUpdating
            ? SizedBox(
                width: tokens.iconSizeSm,
                height: tokens.iconSizeSm,
                child: CircularProgressIndicator.adaptive(
                  key: const Key('movie-detail-hero-more-actions-loading'),
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color?>(
                    context.appTextPalette.secondary,
                  ),
                ),
              )
            : Icon(
                Icons.more_horiz_rounded,
                size: tokens.iconSizeSm,
                color: context.appTextPalette.secondary,
              ),
      ),
    );

    if (onTap == null || isUpdating) {
      return Tooltip(message: '更多操作', child: button);
    }

    return Tooltip(
      message: '更多操作',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) => onTap!(details.globalPosition),
          child: button,
        ),
      ),
    );
  }
}
