import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/overview_card_states.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/features/status/presentation/status_placeholders.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';

/// 媒体资产卡：一组分格数字 + 处理积压与合集资产两行脚注。
///
/// 桌面上是一个横向分格行，窄屏（移动/窄窗口）折成两列网格。
class AssetSummaryCard extends StatelessWidget {
  const AssetSummaryCard({
    super.key,
    required this.status,
    required this.insights,
    required this.pendingIndexCount,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final StatusDto? status;
  final StatusInsightsDto? insights;
  final int pendingIndexCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _AssetHeroSurface(
      key: const Key('overview-asset-summary-card'),
      title: AppLocalizations.of(context).overviewMediaAssets,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading && status == null) {
      // loading 用占位数据渲染真实分格，由 [AppSkeletonizer] 灰化。
      return AppSkeletonizer(
        enabled: true,
        child: _buildLoaded(
          context,
          statusSummaryPlaceholder(),
          statusInsightsPlaceholder(),
        ),
      );
    }
    if (errorMessage != null) {
      return OverviewCardErrorRow(
        message: errorMessage!,
        onRetry: onRetry,
        retryKey: const Key('overview-asset-retry-button'),
      );
    }

    final current = status;
    if (current == null) {
      return Text(
        AppLocalizations.of(context).overviewNoAssetData,
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          weight: AppTextWeight.regular,
          tone: AppTextTone.muted,
        ),
      );
    }
    return _buildLoaded(context, current, insights);
  }

  Widget _buildLoaded(
    BuildContext context,
    StatusDto current,
    StatusInsightsDto? insights,
  ) {
    final l10n = AppLocalizations.of(context);
    final metrics = <_AssetMetric>[
      _AssetMetric(
        id: 'movies',
        label: l10n.overviewMovies,
        value: formatCount(current.movies.total),
        secondary: l10n.overviewMoviePlayableSubscribed(
          formatCount(current.movies.playable),
          formatCount(current.movies.subscribed),
        ),
        narrowSecondary: l10n.overviewMoviePlayable(
          formatCount(current.movies.playable),
        ),
      ),
      _AssetMetric(
        id: 'actors',
        label: l10n.overviewActresses,
        value: formatCount(current.actors.femaleTotal),
        secondary: l10n.overviewSubscribedCount(
          formatCount(current.actors.femaleSubscribed),
        ),
      ),
      _AssetMetric(
        id: 'media-files',
        label: l10n.overviewMediaFiles,
        value: formatCount(current.mediaFiles.total),
        secondary: l10n.overviewLibraryCount(
          formatCount(current.mediaLibraries.total),
        ),
      ),
      _AssetMetric(
        id: 'media-size',
        label: l10n.overviewTotalMediaSize,
        value: formatFileSize(current.mediaFiles.totalSizeBytes),
        secondary: l10n.overviewThumbnails(
          formatCount(current.thumbnails.total),
        ),
      ),
    ];

    final backlog = _buildBacklogItems(current, l10n);
    final collections = _buildCollectionItems(insights?.collections, l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _twoColumnMinWidth;
        final rows = narrow
            ? <List<_AssetMetric>>[metrics.sublist(0, 2), metrics.sublist(2, 4)]
            : <List<_AssetMetric>>[metrics];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var index = 0; index < rows.length; index += 1) ...<Widget>[
              if (index > 0) SizedBox(height: context.appSpacing.xl),
              _AssetMetricRow(
                cells: <Widget>[
                  for (final metric in rows[index])
                    _AssetMetricCell(metric: metric, narrow: narrow),
                ],
              ),
            ],
            if (backlog.isNotEmpty || collections.isNotEmpty) ...<Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.appSpacing.lg),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: context.appColors.divider,
                ),
              ),
              if (backlog.isNotEmpty)
                _FootnoteLine(
                  key: const Key('overview-footnote-backlog'),
                  icon: Icons.hourglass_empty_rounded,
                  items: backlog,
                ),
              if (backlog.isNotEmpty && collections.isNotEmpty)
                SizedBox(height: context.appSpacing.md),
              if (collections.isNotEmpty)
                _FootnoteLine(
                  key: const Key('overview-footnote-collections'),
                  icon: Icons.folder_outlined,
                  prefix: l10n.overviewCollectionsPrefix,
                  items: collections,
                ),
            ],
          ],
        );
      },
    );
  }

  List<_FootnoteItem> _buildBacklogItems(
    StatusDto status,
    AppLocalizations l10n,
  ) {
    final thumbnails = status.thumbnails;
    return <_FootnoteItem>[
      if (thumbnails.pendingMedia > 0)
        _FootnoteItem(
          label: l10n.overviewPendingThumbnails,
          count: thumbnails.pendingMedia,
        ),
      if (pendingIndexCount > 0)
        _FootnoteItem(
          label: l10n.overviewPendingIndex,
          count: pendingIndexCount,
        ),
    ];
  }

  List<_FootnoteItem> _buildCollectionItems(
    CollectionsStatsDto? collections,
    AppLocalizations l10n,
  ) {
    if (collections == null || collections.isEmpty) {
      return const <_FootnoteItem>[];
    }
    return <_FootnoteItem>[
      if (collections.playlists.count > 0)
        _FootnoteItem(
          label: l10n.overviewPlaylists,
          count: collections.playlists.count,
        ),
      if (collections.videoCollections.count > 0)
        _FootnoteItem(
          label: l10n.overviewVideoCollections,
          count: collections.videoCollections.count,
        ),
      if (collections.clipCollections.count > 0)
        _FootnoteItem(
          label: l10n.overviewClipCollections,
          count: collections.clipCollections.count,
        ),
      if (collections.momentCollections.count > 0)
        _FootnoteItem(
          label: l10n.overviewMomentCollections,
          count: collections.momentCollections.count,
        ),
    ];
  }
}

/// 窄屏（卡片内容宽 < 该值）时指标折成两列。
const double _twoColumnMinWidth = 520;

class _AssetMetric {
  const _AssetMetric({
    required this.id,
    required this.label,
    required this.value,
    required this.secondary,
    this.narrowSecondary,
  });

  final String id;
  final String label;
  final String value;

  /// 副文案；窄卡片放不下多个事实时退到 [narrowSecondary]。
  final String secondary;
  final String? narrowSecondary;
}

class _AssetMetricRow extends StatelessWidget {
  const _AssetMetricRow({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var index = 0; index < cells.length; index += 1) ...<Widget>[
            if (index > 0)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: context.appColors.divider,
                ),
              ),
            Expanded(child: cells[index]),
          ],
        ],
      ),
    );
  }
}

class _AssetMetricCell extends StatelessWidget {
  const _AssetMetricCell({required this.metric, required this.narrow});

  final _AssetMetric metric;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('overview-asset-${metric.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          metric.label,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.regular,
            tone: AppTextTone.secondary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              resolveAppTextStyle(
                context,
                size: AppTextSize.s20,
                weight: AppTextWeight.semibold,
                tone: AppTextTone.primary,
              ).copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
        ),
        SizedBox(height: context.appSpacing.xs),
        Text(
          narrow
              ? (metric.narrowSecondary ?? metric.secondary)
              : metric.secondary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.regular,
            tone: AppTextTone.muted,
          ),
        ),
      ],
    );
  }
}

class _FootnoteItem {
  const _FootnoteItem({required this.label, required this.count});

  final String label;
  final int count;
}

/// 脚注行：图标用行内 [WidgetSpan] 与文字同排版，天然与首行文字居中对齐，
/// 文本换行时图标也不会错位。
class _FootnoteLine extends StatelessWidget {
  const _FootnoteLine({
    super.key,
    required this.icon,
    required this.items,
    this.prefix,
  });

  final IconData icon;
  final List<_FootnoteItem> items;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final labelStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s12,
      weight: AppTextWeight.regular,
      tone: AppTextTone.secondary,
    );
    final countStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s12,
      weight: AppTextWeight.semibold,
      tone: AppTextTone.primary,
    );
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              icon,
              size: context.appComponentTokens.iconSizeXs,
              color: context.appTextPalette.muted,
            ),
          ),
          WidgetSpan(child: SizedBox(width: context.appSpacing.sm)),
          if (prefix != null) TextSpan(text: prefix, style: labelStyle),
          for (var index = 0; index < items.length; index += 1) ...<InlineSpan>[
            if (index > 0) TextSpan(text: ' · ', style: labelStyle),
            TextSpan(text: '${items[index].label} ', style: labelStyle),
            TextSpan(text: formatCount(items[index].count), style: countStyle),
          ],
        ],
      ),
    );
  }
}

/// 概览页唯一的主卡。
///
/// 借用发现页「观影偏好」的品牌渐变语言，但只保留一层弱光晕和渐变图标块，
/// 不再叠水印图标——两处语义不同，视觉上保持同源而不互相抢焦点。
class _AssetHeroSurface extends StatelessWidget {
  const _AssetHeroSurface({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius.lgBorder;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                appColors.surfaceCard,
                Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.10),
                  appColors.surfaceCard,
                ),
                Color.alphaBlend(
                  colors.secondary.withValues(alpha: 0.16),
                  appColors.surfaceCard,
                ),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -spacing.xxl,
                right: -spacing.xl,
                child: _AssetHeroGlow(color: colors.primary),
              ),
              Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const _AssetHeroIconTile(
                          icon: Icons.video_library_rounded,
                        ),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: resolveAppTextStyle(
                              context,
                              size: AppTextSize.s16,
                              weight: AppTextWeight.semibold,
                              tone: AppTextTone.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.lg),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetHeroIconTile extends StatelessWidget {
  const _AssetHeroIconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: context.appSpacing.xxl,
      height: context.appSpacing.xxl,
      decoration: BoxDecoration(
        borderRadius: context.appRadius.mdBorder,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primary, colors.secondary],
        ),
      ),
      child: Icon(
        icon,
        size: context.appComponentTokens.iconSizeMd,
        color: colors.onPrimary,
      ),
    );
  }
}

class _AssetHeroGlow extends StatelessWidget {
  const _AssetHeroGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = context.appSpacing.xxxl * 3.5;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
