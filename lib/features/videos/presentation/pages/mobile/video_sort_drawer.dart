import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/videos/presentation/controllers/listing/video_filter_state.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/listing/video_filter_sections.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';

/// 弹出视频排序底部抽屉。内容与桌面 `AppListHeader` 的就地浮层面板**完全一致**
/// （同一个 `VideoFilterSectionGroup`），**即时生效**，语义同
/// `showMobileMovieFilterDrawer`。
Future<void> showMobileVideoSortDrawer(
  BuildContext context, {
  required VideoFilterState current,
  required ValueChanged<VideoFilterState> onChanged,
}) {
  return showAppBottomDrawer<void>(
    context: context,
    drawerKey: const Key('mobile-pornbox-sort-drawer'),
    maxHeightFactor: 0.55,
    builder: (sheetContext) => AppMobileFilterDrawer<VideoFilterState>(
      current: current,
      initial: VideoFilterState.initial,
      onChanged: onChanged,
      isDefault: (value) => value.isDefault,
      scrollViewKey: const Key('mobile-pornbox-sort-scroll-view'),
      contentBuilder: (context, local, onApply) =>
          VideoFilterSectionGroup(filterState: local, onChanged: onApply),
    ),
  );
}
