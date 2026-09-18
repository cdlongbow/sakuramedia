import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/overview_card_states.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_content_card.dart';

/// 观看趋势卡：时间窗口分段 + 自绘柱状图。
///
/// 数据是「每个媒体最后一次观看时间」的分布，不是完整观看历史，
/// 文案保持「看过 N 部」这类当下口径。
class WatchTrendCard extends StatelessWidget {
  const WatchTrendCard({
    super.key,
    required this.trend,
    required this.range,
    required this.onRangeChanged,
    this.compactSelector = false,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final StatusWatchTrendDto? trend;
  final WatchTrendRange range;
  final ValueChanged<WatchTrendRange> onRangeChanged;

  /// 窄卡片（移动端/窄窗口）把分段控件换行到标题下方，并减少可见窗口。
  final bool compactSelector;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final selector = _RangeSelector(
      range: range,
      narrow: compactSelector,
      onChanged: onRangeChanged,
    );

    return AppContentCard(
      key: const Key('overview-watch-trend-card'),
      title: '观看趋势',
      headerTrailing: compactSelector ? null : selector,
      headerBottomSpacing: context.appSpacing.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (compactSelector) ...<Widget>[
            Align(alignment: Alignment.centerLeft, child: selector),
            SizedBox(height: context.appSpacing.lg),
          ],
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (errorMessage != null) {
      return OverviewCardErrorRow(
        message: errorMessage!,
        onRetry: onRetry,
        retryKey: const Key('overview-watch-trend-retry-button'),
      );
    }

    final current = trend;
    final buckets = current?.buckets ?? const <WatchTrendBucketDto>[];
    final watchedCount = current?.watchedMovieCount ?? 0;
    final hasData = !isLoading && buckets.isNotEmpty && watchedCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 摘要行在加载中用同字号的占位文本，保证切换窗口时卡片高度不抖。
        Text(
          isLoading
              ? '正在加载…'
              : '${range.periodLabel}看过 ${formatCount(watchedCount)} 部',
          key: const Key('overview-watch-trend-summary'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.regular,
            tone: AppTextTone.secondary,
          ),
        ),
        SizedBox(height: context.appSpacing.lg),
        SizedBox(
          height: _chartAreaHeight,
          child: isLoading
              ? const _TrendChartPlaceholder()
              : hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _TrendBarChart(
                        buckets: buckets,
                        range: current!.range,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.sm),
                    Padding(
                      padding: EdgeInsets.only(
                        left: _TrendValueAxis.width + context.appSpacing.xs,
                      ),
                      child: _TrendAxisLabels(buckets: buckets),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    '该区间暂无观看记录',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.muted,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// 图表 + 轴标签的固定总高：加载骨架、空态、有数据态共用，避免卡片跳动。
const double _chartAreaHeight = 96;

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.range,
    required this.narrow,
    required this.onChanged,
  });

  static const double _chipHorizontalPadding = 12;
  static const double _chipVerticalPadding = 5;

  final WatchTrendRange range;
  final bool narrow;
  final ValueChanged<WatchTrendRange> onChanged;

  List<WatchTrendRange> get _ranges {
    if (!narrow) {
      return WatchTrendRange.values;
    }
    final base = <WatchTrendRange>[
      WatchTrendRange.last7Days,
      WatchTrendRange.last30Days,
      WatchTrendRange.lastYear,
    ];
    if (!base.contains(range)) {
      base.add(range);
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Container(
      padding: EdgeInsets.all(spacing.xs / 2),
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final item in _ranges)
            _RangeChip(
              range: item,
              isSelected: item == range,
              onTap: () => onChanged(item),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  final WatchTrendRange range;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: _RangeSelector._chipHorizontalPadding,
        vertical: _RangeSelector._chipVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: isSelected ? context.appColors.surfaceCard : null,
        borderRadius: context.appRadius.pillBorder,
        boxShadow: isSelected ? context.appShadows.card : null,
      ),
      child: Text(
        range.shortLabel,
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          weight: isSelected ? AppTextWeight.medium : AppTextWeight.regular,
          tone: isSelected ? AppTextTone.primary : AppTextTone.secondary,
        ),
      ),
    );

    return InkWell(
      key: Key('overview-watch-trend-range-${range.apiValue}'),
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: context.appRadius.pillBorder,
      child: chip,
    );
  }
}

class _TrendChartPlaceholder extends StatelessWidget {
  const _TrendChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.mdBorder,
      ),
    );
  }
}

class _TrendBarChart extends StatelessWidget {
  const _TrendBarChart({required this.buckets, required this.range});

  final List<WatchTrendBucketDto> buckets;
  final WatchTrendRange range;

  @override
  Widget build(BuildContext context) {
    final counts = buckets.map((bucket) => bucket.count).toList(growable: false);
    final axisMax = _niceAxisMax(counts.reduce(math.max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _TrendValueAxis(maxValue: axisMax),
        SizedBox(width: context.appSpacing.xs),
        Expanded(
          child: CustomPaint(
            key: const Key('overview-watch-trend-chart'),
            painter: _TrendBarChartPainter(
              counts: counts,
              axisMax: axisMax,
              barColor: Theme.of(context).colorScheme.primary,
              emptyBarColor: context.appColors.borderSubtle,
              gridColor: context.appColors.borderSubtle,
              baselineColor: context.appColors.divider,
              barRadius: context.appRadius.xs,
              gap: buckets.length > 24 ? 2 : 6,
            ),
          ),
        ),
      ],
    );
  }
}

/// 把纵轴上限取整到 1/2/5 的整数倍，让刻度好读（如 43 → 50）。
int _niceAxisMax(int maxCount) {
  if (maxCount <= 10) {
    return maxCount;
  }
  var magnitude = 1;
  while (magnitude * 10 <= maxCount) {
    magnitude *= 10;
  }
  for (final factor in <int>[1, 2, 5, 10]) {
    final candidate = magnitude * factor;
    if (candidate >= maxCount) {
      return candidate;
    }
  }
  return magnitude * 10;
}

/// 纵轴刻度：顶部为量程上限（与最高柱齐平的那条线），底部为 0。
class _TrendValueAxis extends StatelessWidget {
  const _TrendValueAxis({required this.maxValue});

  static const double width = 24;

  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final style = resolveAppTextStyle(
      context,
      size: AppTextSize.s10,
      weight: AppTextWeight.regular,
      tone: AppTextTone.muted,
    );
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: 0,
            right: 0,
            child: _AxisTickLabel(text: formatCount(maxValue), style: style),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _AxisTickLabel(text: '0', style: style),
          ),
        ],
      ),
    );
  }
}

/// 零高度 + 上下对称溢出：让刻度文字的中心精确落在对应网格线上。
class _AxisTickLabel extends StatelessWidget {
  const _AxisTickLabel({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _TrendValueAxis.width,
      height: 0,
      child: OverflowBox(
        alignment: Alignment.centerRight,
        maxWidth: _TrendValueAxis.width,
        maxHeight: 32,
        child: Text(text, style: style, maxLines: 1),
      ),
    );
  }
}

class _TrendBarChartPainter extends CustomPainter {
  const _TrendBarChartPainter({
    required this.counts,
    required this.axisMax,
    required this.barColor,
    required this.emptyBarColor,
    required this.gridColor,
    required this.baselineColor,
    required this.barRadius,
    required this.gap,
  });

  static const double _emptyBarHeight = 2;
  static const double _minBarHeight = 4;

  final List<int> counts;
  final int axisMax;
  final Color barColor;
  final Color emptyBarColor;
  final Color gridColor;
  final Color baselineColor;
  final double barRadius;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty || size.width <= 0 || axisMax <= 0) {
      return;
    }
    final slot = size.width / counts.length;
    final barWidth = math.max(1.5, slot - gap);
    final fill = Paint()..style = PaintingStyle.fill;

    // 量程上限与 0 的两条参考线，对齐左侧刻度文字。
    final line = Paint()..strokeWidth = 1;
    line.color = gridColor;
    canvas.drawLine(const Offset(0, 0.5), Offset(size.width, 0.5), line);
    line.color = baselineColor;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      line,
    );

    for (var index = 0; index < counts.length; index += 1) {
      final count = counts[index];
      final isEmpty = count == 0;
      final height = isEmpty
          ? _emptyBarHeight
          : math.max(_minBarHeight, size.height * count / axisMax);
      final rect = Rect.fromLTWH(
        index * slot + (slot - barWidth) / 2,
        size.height - height,
        barWidth,
        height,
      );
      fill.color = isEmpty ? emptyBarColor : barColor;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(barRadius),
          topRight: Radius.circular(barRadius),
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendBarChartPainter oldDelegate) {
    return oldDelegate.axisMax != axisMax ||
        oldDelegate.barColor != barColor ||
        oldDelegate.emptyBarColor != emptyBarColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.baselineColor != baselineColor ||
        oldDelegate.barRadius != barRadius ||
        oldDelegate.gap != gap ||
        !listEquals(oldDelegate.counts, counts);
  }
}

class _TrendAxisLabels extends StatelessWidget {
  const _TrendAxisLabels({required this.buckets});

  final List<WatchTrendBucketDto> buckets;

  @override
  Widget build(BuildContext context) {
    final labelStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s10,
      weight: AppTextWeight.regular,
      tone: AppTextTone.muted,
    );
    return Row(
      children: <Widget>[
        Text(_formatPeriod(buckets.first.period), style: labelStyle),
        const Spacer(),
        Text(_formatPeriod(buckets.last.period), style: labelStyle),
      ],
    );
  }
}

String _formatPeriod(String period) {
  if (period.length == 10) {
    return period.substring(5);
  }
  return period;
}
