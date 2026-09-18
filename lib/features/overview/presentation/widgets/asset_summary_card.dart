import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/overview_card_states.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_content_card.dart';

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
    return AppContentCard(
      key: const Key('overview-asset-summary-card'),
      title: '媒体资产',
      headerBottomSpacing: context.appSpacing.lg,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const OverviewCardLoadingBars(rows: 2);
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
        '暂无媒体资产数据',
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          weight: AppTextWeight.regular,
          tone: AppTextTone.muted,
        ),
      );
    }

    final metrics = <_AssetMetric>[
      _AssetMetric(
        id: 'movies',
        label: '影片',
        value: formatCount(current.movies.total),
        secondary:
            '可播放 ${formatCount(current.movies.playable)} · 已订阅 ${formatCount(current.movies.subscribed)}',
        narrowSecondary: '可播放 ${formatCount(current.movies.playable)}',
      ),
      _AssetMetric(
        id: 'actors',
        label: '女优',
        value: formatCount(current.actors.femaleTotal),
        secondary: '已订阅 ${formatCount(current.actors.femaleSubscribed)}',
      ),
      _AssetMetric(
        id: 'media-files',
        label: '媒体文件',
        value: formatCount(current.mediaFiles.total),
        secondary: '${formatCount(current.mediaLibraries.total)} 个资源库',
      ),
      _AssetMetric(
        id: 'media-size',
        label: '媒体总量',
        value: formatFileSize(current.mediaFiles.totalSizeBytes),
        secondary: '缩略图 ${formatCount(current.thumbnails.total)}',
      ),
    ];

    final backlog = _buildBacklogItems(current);
    final collections = _buildCollectionItems(insights?.collections);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _twoColumnMinWidth;
        final rows = narrow
            ? <List<_AssetMetric>>[
                metrics.sublist(0, 2),
                metrics.sublist(2, 4),
              ]
            : <List<_AssetMetric>>[metrics];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var index = 0; index < rows.length; index += 1) ...<Widget>[
              if (index > 0) SizedBox(height: context.appSpacing.xl),
              _AssetMetricRow(metrics: rows[index], narrow: narrow),
            ],
            if (backlog.isNotEmpty || collections.isNotEmpty) ...<Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.appSpacing.lg,
                ),
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
                  prefix: '合集：',
                  items: collections,
                ),
            ],
          ],
        );
      },
    );
  }

  List<_FootnoteItem> _buildBacklogItems(StatusDto status) {
    final thumbnails = status.thumbnails;
    return <_FootnoteItem>[
      if (thumbnails.pendingMedia > 0)
        _FootnoteItem(label: '待生成缩略图', count: thumbnails.pendingMedia),
      if (pendingIndexCount > 0)
        _FootnoteItem(label: '待索引', count: pendingIndexCount),
    ];
  }

  List<_FootnoteItem> _buildCollectionItems(CollectionsStatsDto? collections) {
    if (collections == null || collections.isEmpty) {
      return const <_FootnoteItem>[];
    }
    return <_FootnoteItem>[
      if (collections.playlists.count > 0)
        _FootnoteItem(label: '播放列表', count: collections.playlists.count),
      if (collections.videoCollections.count > 0)
        _FootnoteItem(
          label: '视频合集',
          count: collections.videoCollections.count,
        ),
      if (collections.clipCollections.count > 0)
        _FootnoteItem(label: '片段合集', count: collections.clipCollections.count),
      if (collections.momentCollections.count > 0)
        _FootnoteItem(
          label: '时刻合集',
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
  const _AssetMetricRow({required this.metrics, required this.narrow});

  final List<_AssetMetric> metrics;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var index = 0; index < metrics.length; index += 1) ...<Widget>[
            if (index > 0)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: context.appColors.divider,
                ),
              ),
            Expanded(
              child: _AssetMetricCell(
                metric: metrics[index],
                narrow: narrow,
              ),
            ),
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
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s20,
            weight: AppTextWeight.semibold,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.xs),
        Text(
          narrow ? (metric.narrowSecondary ?? metric.secondary) : metric.secondary,
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
