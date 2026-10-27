import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/videos/presentation/controllers/listing/video_filter_state.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/widgets/base/navigation/app_sort_menu_button.dart';

/// 视频列表的排序入口适配器。
class VideoSortMenuButton extends StatelessWidget {
  const VideoSortMenuButton({
    super.key,
    required this.filterState,
    required this.onChanged,
    this.useDrawer = false,
    this.keyPrefix = 'videos',
    this.triggerKey,
    this.panelKey,
    this.drawerKey,
  });

  final VideoFilterState filterState;
  final ValueChanged<VideoFilterState> onChanged;
  final bool useDrawer;
  final String keyPrefix;
  final Key? triggerKey;
  final Key? panelKey;
  final Key? drawerKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppSortMenuButton<VideoSortField>(
      fields: VideoSortField.values,
      selectedField: filterState.sortField,
      fieldLabelBuilder: (value) => value.labelWith(l10n),
      onFieldChanged: (value) =>
          onChanged(filterState.copyWith(sortField: value!)),
      selectedDirection: filterState.sortDirection,
      onDirectionChanged: (value) =>
          onChanged(filterState.copyWith(sortDirection: value)),
      useDrawer: useDrawer,
      triggerKey: triggerKey,
      panelKey: panelKey,
      drawerKey: drawerKey,
      fieldKeyBuilder: (value) => Key('$keyPrefix-sort-field-${value.name}'),
      directionKeyBuilder: (value) =>
          Key('$keyPrefix-sort-direction-${value.name}'),
    );
  }
}
