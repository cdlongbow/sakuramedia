import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/videos/presentation/controllers/listing/video_filter_state.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_filter_sections.dart';

/// 视频列表筛选所有 section 的纵向 Column。
///
/// 桌面 `AppListHeader` 的就地浮层 panel 和移动筛选抽屉都用它，避免双份维护。
/// 底栏/重置按钮由调用方自己附加。排序不在筛选面板里，见
/// `VideoSortMenuButton`。
class VideoFilterSectionGroup extends StatelessWidget {
  const VideoFilterSectionGroup({
    super.key,
    required this.filterState,
    required this.onChanged,
  });

  final VideoFilterState filterState;
  final ValueChanged<VideoFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MovieFilterChoiceSection<bool>(
          title: '合集',
          options: const <bool>[false, true],
          selectedValue: filterState.uncollected,
          optionKeyBuilder: (uncollected) => Key(
            uncollected
                ? 'videos-filter-collection-uncollected'
                : 'videos-filter-collection-all',
          ),
          labelBuilder: (uncollected) => uncollected ? '未加入合集' : '全部',
          onSelected: (uncollected) =>
              onChanged(filterState.copyWith(uncollected: uncollected)),
        ),
      ],
    );
  }
}
