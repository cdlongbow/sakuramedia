import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_filter_state.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_filter_sections.dart';

/// 播放列表影片筛选的所有 section（分辨率）的纵向 Column。
///
/// 桌面 `AppListHeader` 的就地浮层 panel 和移动筛选底部抽屉都用它，
/// 避免双份维护。底栏/重置按钮由调用方自己附加。排序不在筛选面板里，
/// 见 `PlaylistSortMenuButton`。
class PlaylistFilterSectionGroup extends StatelessWidget {
  const PlaylistFilterSectionGroup({
    super.key,
    required this.filterState,
    required this.onChanged,
  });

  final PlaylistFilterState filterState;
  final ValueChanged<PlaylistFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MovieFilterChoiceSection<PlaylistResolutionFilter?>(
      title: l10n.playlistFilterResolution,
      options: const [null, ...PlaylistResolutionFilter.values],
      selectedValue: filterState.resolution,
      labelBuilder: (value) => value?.label ?? l10n.playlistFilterAll,
      optionKeyBuilder: (value) =>
          Key('playlist-filter-resolution-${value?.apiValue ?? 'all'}'),
      onSelected: (value) => onChanged(filterState.copyWith(resolution: value)),
    );
  }
}
