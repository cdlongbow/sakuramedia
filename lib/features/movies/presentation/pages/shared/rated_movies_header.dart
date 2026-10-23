import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/rating/rating_dimension_dto.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_summary_list_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/rating_dimensions_provider.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/rating/rating_dimensions_dialog.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_sort_menu_button.dart';

/// 「我的评分」页顶栏；桌面浮层与移动抽屉共用同一个排序入口。
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

    final selectedValue = args.filterState.dimensionSortId == null
        ? 'total'
        : 'dimension:${args.filterState.dimensionSortId}';

    return AppListHeader(
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
        AppSortMenuButton<String>(
          fields: <String>[
            'total',
            for (final dimension in dimensions) 'dimension:${dimension.id}',
          ],
          selectedField: selectedValue,
          fieldLabelBuilder: (value) => _dimensionLabel(value, dimensions),
          onFieldChanged: (newValue) {
            final value = newValue!;
            if (value == 'total') {
              args.onApply(
                args.filterState.copyWith(
                  sortField: MovieSortField.myScore,
                  dimensionSortId: null,
                ),
              );
              return;
            }
            final dimensionId = int.tryParse(value.split(':').last);
            if (dimensionId != null) {
              args.onApply(
                args.filterState.copyWith(dimensionSortId: dimensionId),
              );
            }
          },
          selectedDirection: args.filterState.sortDirection,
          onDirectionChanged: (value) =>
              args.onApply(args.filterState.copyWith(sortDirection: value)),
          useDrawer: isMobile,
          triggerKey: const Key('rated-movies-sort-trigger'),
          panelKey: const Key('rated-movies-sort-panel'),
          drawerKey: const Key('mobile-rated-movies-sort-drawer'),
          fieldKeyBuilder: (value) => Key(
            value == 'total'
                ? 'rated-movies-sort-total'
                : 'rated-movies-sort-dimension-${value.split(':').last}',
          ),
          directionKeyBuilder: (value) =>
              Key('rated-movies-sort-${value.apiValue}'),
        ),
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

String _dimensionLabel(String value, List<RatingDimensionDto> dimensions) {
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
