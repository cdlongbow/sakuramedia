import 'package:flutter/material.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_resolution_option_dto.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_filter_state.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_resolution_options_controller.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';

/// 播放列表影片筛选的所有 section（分辨率 / 排序）的纵向 Column。
///
/// 桌面 `AppListHeader` 的就地浮层 panel 和移动筛选底部抽屉都用它，
/// 避免双份维护。底栏/重置按钮由调用方自己附加。
///
/// **分辨率状态用 [PlaylistResolutionOptionsController]（`ChangeNotifier`）
/// 订阅**——移动抽屉是 modal route，快照式挂载不会被父级 `setState` 唤醒；
/// 用 controller 让桌面/移动都实时跟随后端返回，避免「抽屉里重试永远转圈」
/// 的历史 bug。
class PlaylistFilterSectionGroup extends StatelessWidget {
  const PlaylistFilterSectionGroup({
    super.key,
    required this.filterState,
    required this.onChanged,
    required this.resolutionOptions,
  });

  final PlaylistFilterState filterState;
  final ValueChanged<PlaylistFilterState> onChanged;
  final PlaylistResolutionOptionsController resolutionOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListenableBuilder(
          listenable: resolutionOptions,
          builder:
              (context, _) => _PlaylistResolutionSection(
                options: resolutionOptions.options,
                selectedResolution: filterState.resolution,
                isLoading: resolutionOptions.isLoading,
                errorMessage: resolutionOptions.errorMessage,
                onRetry: () => resolutionOptions.retry(),
                onSelected:
                    (value) =>
                        onChanged(filterState.copyWith(resolution: value)),
              ),
        ),
        SizedBox(height: context.appSpacing.lg),
        _PlaylistSortSection(filterState: filterState, onChanged: onChanged),
      ],
    );
  }
}

class _PlaylistResolutionSection extends StatelessWidget {
  const _PlaylistResolutionSection({
    required this.options,
    required this.selectedResolution,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onSelected,
  });

  final List<PlaylistResolutionOptionDto> options;
  final PlaylistResolutionFilter? selectedResolution;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<PlaylistResolutionFilter?> onSelected;

  @override
  Widget build(BuildContext context) {
    // 「有数据」优先渲染 chips，再把 loading / error 降级为行内小提示；
    // 只有从未成功过、彻底没数据时才让 loading / error 独占内容区。
    // 避免二次刷新失败把已有的档位 chips 抹掉。
    final hasOptions = options.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分辨率',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        if (hasOptions)
          _ResolutionChips(
            options: options,
            selectedResolution: selectedResolution,
            onSelected: onSelected,
          )
        else if (isLoading)
          _ResolutionInlineStatus(text: '分辨率加载中', showSpinner: true)
        else if (errorMessage != null)
          _ResolutionInlineStatus(
            text: errorMessage!,
            trailing: AppTextButton(
              label: '重试',
              size: AppTextButtonSize.xSmall,
              onPressed: onRetry,
            ),
          ),
        // 有数据 + 后续刷新出错 → 底下追一行小提示，chips 不动。
        if (hasOptions && errorMessage != null) ...[
          SizedBox(height: context.appSpacing.xs),
          _ResolutionInlineStatus(
            text: errorMessage!,
            trailing: AppTextButton(
              label: '重试',
              size: AppTextButtonSize.xSmall,
              onPressed: onRetry,
            ),
          ),
        ],
        // 有数据 + 后台刷新 → 底下追一个 spinner，chips 不动。
        if (hasOptions && isLoading && errorMessage == null) ...[
          SizedBox(height: context.appSpacing.xs),
          _ResolutionInlineStatus(text: '分辨率刷新中', showSpinner: true),
        ],
      ],
    );
  }
}

class _ResolutionChips extends StatelessWidget {
  const _ResolutionChips({
    required this.options,
    required this.selectedResolution,
    required this.onSelected,
  });

  final List<PlaylistResolutionOptionDto> options;
  final PlaylistResolutionFilter? selectedResolution;
  final ValueChanged<PlaylistResolutionFilter?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.appSpacing.sm,
      runSpacing: context.appSpacing.sm,
      children: [
        AppTextButton(
          key: const Key('playlist-filter-resolution-all'),
          label: '全部',
          size: AppTextButtonSize.xSmall,
          isSelected: selectedResolution == null,
          onPressed: () => onSelected(null),
        ),
        for (final option in options)
          AppTextButton(
            key: Key('playlist-filter-resolution-${option.resolution}'),
            label: '${option.resolution}(${option.count})',
            size: AppTextButtonSize.xSmall,
            isSelected: option.resolution == selectedResolution?.apiValue,
            onPressed:
                () => onSelected(
                  PlaylistResolutionFilterX.fromApiValue(option.resolution),
                ),
          ),
      ],
    );
  }
}

class _ResolutionInlineStatus extends StatelessWidget {
  const _ResolutionInlineStatus({
    required this.text,
    this.showSpinner = false,
    this.trailing,
  });

  final String text;
  final bool showSpinner;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: context.appSpacing.sm),
        ],
        Text(
          text,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.regular,
            tone: AppTextTone.muted,
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: context.appSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class _PlaylistSortSection extends StatelessWidget {
  const _PlaylistSortSection({
    required this.filterState,
    required this.onChanged,
  });

  final PlaylistFilterState filterState;
  final ValueChanged<PlaylistFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final sortField = filterState.sortField;
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
          children: [
            // 最近触达 = 不传 sort，走后端默认（最近触达/入库倒序）。
            AppTextButton(
              key: const Key('playlist-filter-sort-recent'),
              label: '最近触达',
              size: AppTextButtonSize.xSmall,
              isSelected: sortField == null,
              onPressed: () => onChanged(filterState.copyWith(sortField: null)),
            ),
            for (final field in PlaylistSortField.values)
              AppTextButton(
                key: Key('playlist-filter-sort-${field.apiValue}'),
                label: field.label,
                size: AppTextButtonSize.xSmall,
                isSelected: field == sortField,
                onPressed:
                    () => onChanged(filterState.copyWith(sortField: field)),
              ),
          ],
        ),
        if (sortField != null) ...[
          SizedBox(height: context.appSpacing.md),
          Text(
            '升降序',
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
            children: SortDirection.values
                .map(
                  (direction) => AppTextButton(
                    key: Key(
                      'playlist-filter-sort-direction-'
                      '${direction == SortDirection.desc ? 'desc' : 'asc'}',
                    ),
                    label: direction == SortDirection.desc ? '降序' : '升序',
                    size: AppTextButtonSize.xSmall,
                    isSelected: direction == filterState.sortDirection,
                    onPressed:
                        () => onChanged(
                          filterState.copyWith(sortDirection: direction),
                        ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
