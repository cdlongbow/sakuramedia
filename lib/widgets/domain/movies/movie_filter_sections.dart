import 'package:flutter/material.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';

/// 影片筛选的所有 section（状态 / 合集类型 / 番号来源 / 年份 / 排序）的纵向 Column。
///
/// 桌面 `AppListHeader` 的就地浮层 panel 和移动 `MobileMovieFilterDrawer` 都用它，
/// 避免双份维护。底栏/重置按钮由调用方自己附加。
class MovieFilterSectionGroup extends StatelessWidget {
  const MovieFilterSectionGroup({
    super.key,
    required this.filterState,
    required this.onChanged,
    this.yearOptions,
    this.isYearOptionsLoading = false,
    this.yearOptionsErrorMessage,
    this.onYearOptionsRetry,
  });

  final MovieFilterState filterState;
  final ValueChanged<MovieFilterState> onChanged;

  /// `null` 表示普通影片库，使用前端生成的 2008 年至当前年的固定范围；
  /// 女优详情传入非空列表，以展示接口返回的影片数量。
  final List<MovieFilterYearOption>? yearOptions;
  final bool isYearOptionsLoading;
  final String? yearOptionsErrorMessage;
  final VoidCallback? onYearOptionsRetry;

  bool get _shouldShowYearSection =>
      yearOptions == null ||
      yearOptions!.isNotEmpty ||
      isYearOptionsLoading ||
      yearOptionsErrorMessage != null ||
      filterState.year != null;

  @override
  Widget build(BuildContext context) {
    final resolvedYearOptions =
        yearOptions ?? buildDefaultMovieFilterYearOptions();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MovieFilterChoiceSection<MovieStatusFilter>(
          title: '状态筛选',
          options: MovieStatusFilter.values,
          selectedValue: filterState.status,
          labelBuilder: (value) => value.label,
          onSelected: (value) => onChanged(filterState.copyWith(status: value)),
        ),
        SizedBox(height: context.appSpacing.lg),
        MovieFilterChoiceSection<MovieCollectionTypeFilter>(
          title: '合集类型',
          options: MovieCollectionTypeFilter.values,
          selectedValue: filterState.collectionType,
          labelBuilder: (value) => value.label,
          onSelected: (value) =>
              onChanged(filterState.copyWith(collectionType: value)),
        ),
        SizedBox(height: context.appSpacing.lg),
        MovieFilterChoiceSection<MovieNumberSourceFilter>(
          title: '番号来源',
          options: MovieNumberSourceFilter.values,
          selectedValue: filterState.numberSource,
          labelBuilder: (value) => value.label,
          onSelected: (value) =>
              onChanged(filterState.copyWith(numberSource: value)),
        ),
        if (_shouldShowYearSection) ...[
          SizedBox(height: context.appSpacing.lg),
          MovieYearFilterSection(
            options: resolvedYearOptions,
            selectedYear: filterState.year,
            isLoading: isYearOptionsLoading,
            errorMessage: yearOptionsErrorMessage,
            onRetry: onYearOptionsRetry,
            onSelected: (value) => onChanged(filterState.copyWith(year: value)),
          ),
        ],
        SizedBox(height: context.appSpacing.lg),
        MovieSortSection(
          filterState: filterState,
          onSortFieldChanged: (value) =>
              onChanged(filterState.copyWith(sortField: value)),
          onSortDirectionChanged: (value) =>
              onChanged(filterState.copyWith(sortDirection: value)),
        ),
      ],
    );
  }
}

class MovieFilterChoiceSection<T> extends StatelessWidget {
  const MovieFilterChoiceSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
    this.optionKeyBuilder,
  });

  final String title;
  final List<T> options;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  /// 给每个选项 chip 生成稳定 Key（测试锚点）。语义对齐
  /// `RankingFilterChoiceSection.optionKeyBuilder`；不传则不挂 Key。
  final Key Function(T value)? optionKeyBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        Wrap(
          spacing: context.appSpacing.sm,
          runSpacing: context.appSpacing.sm,
          children: options
              .map(
                (value) => AppTextButton(
                  key: optionKeyBuilder?.call(value),
                  label: labelBuilder(value),
                  size: AppTextButtonSize.xSmall,
                  isSelected: value == selectedValue,
                  onPressed: () => onSelected(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class MovieYearFilterSection extends StatefulWidget {
  const MovieYearFilterSection({
    super.key,
    required this.options,
    required this.selectedYear,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onSelected,
  });

  final List<MovieFilterYearOption> options;
  final int? selectedYear;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<int?> onSelected;

  @override
  State<MovieYearFilterSection> createState() => _MovieYearFilterSectionState();
}

class _MovieYearFilterSectionState extends State<MovieYearFilterSection> {
  static const int _collapsedRowCount = 2;

  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // 当前已选年份可能在两行之外；首次打开时直接展开，避免筛选条件不可见。
    _isExpanded = widget.selectedYear != null;
  }

  @override
  void didUpdateWidget(covariant MovieYearFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedYear != oldWidget.selectedYear &&
        widget.selectedYear != null) {
      _isExpanded = true;
    }
  }

  List<_MovieYearChoice> get _choices => <_MovieYearChoice>[
    const _MovieYearChoice(value: null, label: '全部年份'),
    for (final option in widget.options)
      _MovieYearChoice(value: option.year, label: option.label),
  ];

  int _collapsedChoiceCount(
    BuildContext context,
    List<_MovieYearChoice> choices,
    double maxWidth,
  ) {
    if (!maxWidth.isFinite || maxWidth <= 0) {
      return choices.length;
    }

    final componentTokens = context.appComponentTokens;
    final gap = context.appSpacing.sm;
    final labelStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s12,
      tone: AppTextTone.muted,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    var visibleCount = 0;
    var row = 1;
    var rowWidth = 0.0;

    for (final choice in choices) {
      final painter = TextPainter(
        text: TextSpan(text: choice.label, style: labelStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final choiceWidth =
          (painter.width + componentTokens.buttonHorizontalPaddingXs * 2)
              .clamp(0.0, maxWidth)
              .toDouble();
      final nextWidth = rowWidth == 0
          ? choiceWidth
          : rowWidth + gap + choiceWidth;
      if (rowWidth > 0 && nextWidth > maxWidth) {
        row += 1;
        if (row > _collapsedRowCount) {
          break;
        }
        rowWidth = choiceWidth;
      } else {
        rowWidth = nextWidth;
      }
      visibleCount += 1;
    }
    return visibleCount;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '发行年份',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        if (widget.isLoading)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: context.appSpacing.sm),
              Text(
                '年份加载中',
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.muted,
                ),
              ),
            ],
          )
        else if (widget.errorMessage != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.errorMessage!,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.muted,
                ),
              ),
              SizedBox(width: context.appSpacing.sm),
              AppTextButton(
                label: '重试',
                size: AppTextButtonSize.xSmall,
                onPressed: widget.onRetry,
              ),
            ],
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final choices = _choices;
              final collapsedCount = _collapsedChoiceCount(
                context,
                choices,
                constraints.maxWidth,
              );
              final hasHiddenChoices = choices.length > collapsedCount;
              final visibleChoices = _isExpanded || !hasHiddenChoices
                  ? choices
                  : choices.take(collapsedCount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: context.appSpacing.sm,
                    runSpacing: context.appSpacing.sm,
                    children: [
                      for (final choice in visibleChoices)
                        AppTextButton(
                          key: Key(
                            choice.value == null
                                ? 'movie-filter-year-all'
                                : 'movie-filter-year-${choice.value}',
                          ),
                          label: choice.label,
                          size: AppTextButtonSize.xSmall,
                          isSelected: choice.value == widget.selectedYear,
                          onPressed: () => widget.onSelected(choice.value),
                        ),
                    ],
                  ),
                  if (hasHiddenChoices) ...[
                    SizedBox(height: context.appSpacing.sm),
                    AppTextButton(
                      key: const Key('movie-filter-year-expand-toggle'),
                      label: _isExpanded ? '收起年份' : '展开全部年份',
                      size: AppTextButtonSize.xSmall,
                      trailingIcon: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                      onPressed: () => setState(() {
                        _isExpanded = !_isExpanded;
                      }),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _MovieYearChoice {
  const _MovieYearChoice({required this.value, required this.label});

  final int? value;
  final String label;
}

class MovieSortSection extends StatelessWidget {
  const MovieSortSection({
    super.key,
    required this.filterState,
    required this.onSortFieldChanged,
    required this.onSortDirectionChanged,
  });

  final MovieFilterState filterState;
  final ValueChanged<MovieSortField> onSortFieldChanged;
  final ValueChanged<SortDirection> onSortDirectionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '排序方式',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        Wrap(
          spacing: context.appSpacing.sm,
          runSpacing: context.appSpacing.sm,
          children: MovieSortField.values
              .map(
                (value) => AppTextButton(
                  label: value.label,
                  size: AppTextButtonSize.xSmall,
                  isSelected: value == filterState.sortField,
                  onPressed: () => onSortFieldChanged(value),
                ),
              )
              .toList(growable: false),
        ),
        SizedBox(height: context.appSpacing.md),
        Wrap(
          spacing: context.appSpacing.sm,
          children: SortDirection.values
              .map(
                (value) => AppTextButton(
                  label: value.label,
                  size: AppTextButtonSize.xSmall,
                  isSelected: value == filterState.sortDirection,
                  onPressed: () => onSortDirectionChanged(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
