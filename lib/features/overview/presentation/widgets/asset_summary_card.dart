import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/overview_card_states.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';
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
      return const _AssetSummarySkeleton();
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
              _AssetMetricRow(
                cells: <Widget>[
                  for (final metric in rows[index])
                    _AssetMetricCell(metric: metric, narrow: narrow),
                ],
              ),
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

/// 加载骨架：与真实分格同形——宽卡片一行四格，窄卡片两行两格，复用真实分格的
/// 格子行；每格用「标签 / 数值 / 副文案」三条灰条占位。脚注区按「积压 + 合集
/// 两行都在」的完整形态预留，加载完成后内容只会往下收，不会凭空多出一截。
class _AssetSummarySkeleton extends StatelessWidget {
  const _AssetSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _twoColumnMinWidth;
        final rows = narrow ? 2 : 1;
        final cellsPerRow = narrow ? 2 : 4;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var index = 0; index < rows; index += 1) ...<Widget>[
              if (index > 0) SizedBox(height: context.appSpacing.xl),
              _AssetMetricRow(
                cells: List<Widget>.generate(
                  cellsPerRow,
                  (_) => const _AssetMetricCellSkeleton(),
                ),
              ),
            ],
            const _FootnoteSkeleton(),
          ],
        );
      },
    );
  }
}

class _AssetMetricCellSkeleton extends StatelessWidget {
  const _AssetMetricCellSkeleton();

  /// 灰条高度对齐真实文字的行高（s12 → 17、s20 → 29），
  /// 让骨架卡在加载结束后不会有明显的整卡高度收缩。
  static const double _labelHeight = 17;
  static const double _valueHeight = 29;
  static const double _secondaryHeight = 17;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppSkeletonBlock(width: 28, height: _labelHeight),
        SizedBox(height: spacing.sm),
        const AppSkeletonBlock(width: 76, height: _valueHeight),
        SizedBox(height: spacing.xs),
        const AppSkeletonBlock(width: 132, height: _secondaryHeight),
      ],
    );
  }
}

/// 脚注区骨架：与真实脚注区同结构——通栏分隔线 + 两行「图标 + 文案」。
/// 真实卡的积压行 / 合集行各自按数据是否为空出现，骨架统一按两行都在预留。
class _FootnoteSkeleton extends StatelessWidget {
  const _FootnoteSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.lg),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.appColors.divider,
          ),
        ),
        const _FootnoteLineSkeleton(textWidth: 176),
        SizedBox(height: spacing.md),
        const _FootnoteLineSkeleton(textWidth: 196),
      ],
    );
  }
}

class _FootnoteLineSkeleton extends StatelessWidget {
  const _FootnoteLineSkeleton({required this.textWidth});

  final double textWidth;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Row(
      children: <Widget>[
        const AppSkeletonBlock(width: 16, height: 16),
        SizedBox(width: spacing.sm),
        AppSkeletonBlock(width: textWidth, height: 17),
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
