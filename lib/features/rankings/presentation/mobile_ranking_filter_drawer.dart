import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/rankings/presentation/providers/ranking_summary_provider.dart';
import 'package:sakuramedia/features/rankings/presentation/providers/ranking_summary_scope.dart';
import 'package:sakuramedia/features/rankings/presentation/providers/ranking_summary_state.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/features/rankings/presentation/widgets/ranking_filter_sections.dart';

/// 弹出移动端榜单筛选底部抽屉。
///
/// 与影片/演员 tab 不同，榜单是「即时生效」——chip 改变立刻 reload。
/// 抽屉里改也是即时（回调直接走 page state 的方法），「确定」只是关闭抽屉的语法。
/// [initialAnchor] 用于 chip 点击后定位到对应 section（source/board/period/sort）。
///
Future<void> showMobileRankingFilterDrawer(
  BuildContext context, {
  required RankingSummaryScope scope,
  RankingFilterAnchor? initialAnchor,
}) {
  return showAppBottomDrawer<void>(
    context: context,
    drawerKey: const Key('mobile-rankings-filter-drawer'),
    maxHeightFactor: 0.6,
    builder:
        (sheetContext) => _MobileRankingFilterDrawerContent(
          scope: scope,
          initialAnchor: initialAnchor,
        ),
  );
}

class _MobileRankingFilterDrawerContent extends ConsumerStatefulWidget {
  const _MobileRankingFilterDrawerContent({
    required this.scope,
    required this.initialAnchor,
  });

  final RankingSummaryScope scope;
  final RankingFilterAnchor? initialAnchor;

  @override
  ConsumerState<_MobileRankingFilterDrawerContent> createState() =>
      _MobileRankingFilterDrawerContentState();
}

class _MobileRankingFilterDrawerContentState
    extends ConsumerState<_MobileRankingFilterDrawerContent> {
  late final RankingFilterSectionKeys _sectionKeys;

  @override
  void initState() {
    super.initState();
    _sectionKeys = RankingFilterSectionKeys();
    final anchor = widget.initialAnchor;
    if (anchor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final keyContext = _sectionKeys.forAnchor(anchor).currentContext;
        if (keyContext != null) {
          Scrollable.ensureVisible(
            keyContext,
            duration: const Duration(milliseconds: 240),
            alignment: 0.05,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters =
        ref.watch(rankingSummaryProvider(widget.scope)).value?.filters ??
        RankingFilterState.initial;
    return AppMobileFilterDrawerScaffold(
      // 榜单没有「恢复默认」语义（来源/榜单必须二选一），故不带 footer。
      scrollViewKey: const Key('mobile-rankings-filter-scroll-view'),
      child: RankingFilterSectionGroup(
        sources: filters.sources,
        selectedSource: filters.selectedSource,
        boards: filters.boards,
        selectedBoard: filters.selectedBoard,
        selectedPeriod: filters.selectedPeriod,
        onSourceChanged:
            (value) => ref
                .read(rankingSummaryProvider(widget.scope).notifier)
                .selectSource(value),
        onBoardChanged:
            (value) => ref
                .read(rankingSummaryProvider(widget.scope).notifier)
                .selectBoard(value),
        onPeriodChanged:
            (value) => ref
                .read(rankingSummaryProvider(widget.scope).notifier)
                .selectPeriod(value),
        selectedSortField: filters.selectedSortField,
        selectedSortDirection: filters.selectedSortDirection,
        onSortChanged:
            (field, direction) => ref
                .read(rankingSummaryProvider(widget.scope).notifier)
                .selectSort(field, direction),
        sectionKeys: _sectionKeys,
      ),
    );
  }
}
