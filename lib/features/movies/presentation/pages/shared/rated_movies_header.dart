import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/rating/rating_dimension_dto.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_summary_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/movies/presentation/providers/rating_dimensions_provider.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/rating/rating_dimensions_dialog.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_filter_sections.dart';

/// 「我的评分」页顶栏；桌面面板与移动底部抽屉共用同一套排序分节。
class RatedMoviesHeader extends ConsumerWidget {
  const RatedMoviesHeader({
    super.key,
    required this.args,
    required this.isMobile,
  });

  final MovieSummaryListHeaderArgs args;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions =
        ref.watch(ratingDimensionsProvider).value ??
        const <RatingDimensionDto>[];

    // 维度可能被本页的「维度管理」删除；选中项消失后回到「总分」，
    // 否则会继续请求已不存在的 dimension_<id>，后端返回 422。
    ref.listen(ratingDimensionsProvider, (_, next) {
      final loaded = next.value;
      final selectedId = args.filterState.dimensionSortId;
      if (loaded == null ||
          selectedId == null ||
          loaded.any((dimension) => dimension.id == selectedId)) {
        return;
      }
      args.onApply(
        args.filterState.copyWith(
          sortField: MovieSortField.myScore,
          dimensionSortId: null,
        ),
      );
    });

    return AppListHeader(
      filterButtonKey: const Key('rated-movies-filter-trigger'),
      filterLabel: _sortLabel(dimensions, args.filterState),
      filterPanelKey: isMobile ? null : const Key('rated-movies-filter-panel'),
      filterPanelExtraWidth: 220,
      onFilterTap: isMobile
          ? () => showMobileRatedMoviesSortDrawer(
              context,
              dimensions: dimensions,
              filterState: args.filterState,
              onChanged: args.onApply,
            )
          : null,
      filterPanelBuilder: isMobile
          ? null
          : (_) => RatedMoviesSortPanel(
              dimensions: dimensions,
              filterState: args.filterState,
              onChanged: args.onApply,
            ),
      informationSlots: [
        AppListHeaderInfo(
          key: Key(
            isMobile
                ? 'mobile-rated-movies-count'
                : 'desktop-rated-movies-count',
          ),
          label: '已评分 ${args.total} 部',
        ),
      ],
      actionSlots: [
        AppTextButton(
          key: const Key('rated-movies-dimension-manage'),
          label: '维度管理',
          icon: const Icon(Icons.tune_rounded),
          size: AppTextButtonSize.xSmall,
          onPressed: () => showRatingDimensionsDialog(context),
        ),
      ],
    );
  }
}

String _sortLabel(
  List<RatingDimensionDto> dimensions,
  MovieFilterState filterState,
) {
  final name = dimensions
      .where((dimension) => dimension.id == filterState.dimensionSortId)
      .firstOrNull
      ?.name;
  return '${name ?? '总分'} · ${filterState.sortDirection.label}';
}

/// 总分为已评维度的平均值，保留一位小数；列表接口已带 `my_score`，
/// 缺失时才用维度分值兜底。
String? ratedTotalLabel(MovieListItemDto movie) {
  final score =
      movie.myScore ??
      (movie.myRatingValues.isEmpty
          ? null
          : movie.myRatingValues.values.reduce((a, b) => a + b) /
                movie.myRatingValues.length);
  return score == null ? null : '总分 ${score.toStringAsFixed(1)}';
}

/// 排序面板：总分 / 各评分维度二选一，再加升降序；与影片列表筛选面板同款分节。
class RatedMoviesSortPanel extends StatelessWidget {
  const RatedMoviesSortPanel({
    super.key,
    required this.dimensions,
    required this.filterState,
    required this.onChanged,
  });

  final List<RatingDimensionDto> dimensions;
  final MovieFilterState filterState;
  final ValueChanged<MovieFilterState> onChanged;

  String get _selectedValue => filterState.dimensionSortId == null
      ? 'total'
      : 'dimension:${filterState.dimensionSortId}';

  String _label(String value) {
    if (value == 'total') {
      return '总分';
    }
    final dimensionId = int.tryParse(value.split(':').last);
    return dimensions
            .where((dimension) => dimension.id == dimensionId)
            .firstOrNull
            ?.name ??
        '维度';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MovieFilterChoiceSection<String>(
          title: '排序方式',
          options: <String>[
            'total',
            for (final dimension in dimensions) 'dimension:${dimension.id}',
          ],
          selectedValue: _selectedValue,
          labelBuilder: _label,
          optionKeyBuilder: (value) => Key(
            value == 'total'
                ? 'rated-movies-sort-total'
                : 'rated-movies-sort-dimension-${value.split(':').last}',
          ),
          onSelected: (value) {
            if (value == 'total') {
              onChanged(
                filterState.copyWith(
                  sortField: MovieSortField.myScore,
                  dimensionSortId: null,
                ),
              );
              return;
            }
            final dimensionId = int.tryParse(value.split(':').last);
            if (dimensionId != null) {
              onChanged(filterState.copyWith(dimensionSortId: dimensionId));
            }
          },
        ),
        SizedBox(height: context.appSpacing.lg),
        MovieFilterChoiceSection<SortDirection>(
          title: '升降序',
          options: SortDirection.values,
          selectedValue: filterState.sortDirection,
          labelBuilder: (value) => value.label,
          optionKeyBuilder: (value) =>
              Key('rated-movies-sort-${value.apiValue}'),
          onSelected: (value) =>
              onChanged(filterState.copyWith(sortDirection: value)),
        ),
      ],
    );
  }
}

Future<void> showMobileRatedMoviesSortDrawer(
  BuildContext context, {
  required List<RatingDimensionDto> dimensions,
  required MovieFilterState filterState,
  required ValueChanged<MovieFilterState> onChanged,
}) {
  return showAppBottomDrawer<void>(
    context: context,
    drawerKey: const Key('mobile-rated-movies-filter-drawer'),
    maxHeightFactor: 0.6,
    builder: (sheetContext) => AppMobileFilterDrawer<MovieFilterState>(
      current: filterState,
      initial:
          MovieSummaryScope.ratedList.initialMovieFilter ??
          MovieFilterState.initial,
      onChanged: onChanged,
      isDefault: (value) =>
          value.sortField == MovieSortField.myScore &&
          value.dimensionSortId == null &&
          value.sortDirection == SortDirection.desc,
      scrollViewKey: const Key('mobile-rated-movies-filter-scroll-view'),
      contentBuilder: (context, local, onApply) => RatedMoviesSortPanel(
        dimensions: dimensions,
        filterState: local,
        onChanged: onApply,
      ),
    ),
  );
}
