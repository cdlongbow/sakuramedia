import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/videos/data/dto/video_collection_dto.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_collections_overview_provider.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/create_video_collection_dialog.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';
import 'package:sakuramedia/widgets/domain/collections/collection_target_picker.dart';

/// 目标合集选择器的呈现形态：桌面弹窗 / 移动端底部抽屉。
enum PickVideoCollectionPresentation { dialog, bottomDrawer }

/// 选择一个目标视频合集（批量加入合集用）。返回选中的合集；取消返回 `null`。
///
/// 与单条即时加入的 [showAddToVideoCollectionDialog] 不同：本弹窗只负责「选中并返回」，
/// 实际加入动作由调用方批量执行。三处「加入合集」选择器共用
/// [showCollectionTargetPicker]，本函数只适配本域的数据源、行文案和新建入口。
Future<VideoCollectionDto?> showPickVideoCollectionDialog(
  BuildContext context, {
  PickVideoCollectionPresentation presentation =
      PickVideoCollectionPresentation.dialog,
  int? excludedCollectionId,
}) {
  return showCollectionTargetPicker<VideoCollectionDto>(
    context: context,
    variant: _variantOf(presentation),
    drawerKey: const Key('pick-video-collection-bottom-sheet'),
    optionKeyPrefix: 'pick-collection-',
    watchCollections: (ref) => ref.watch(videoCollectionsOverviewProvider),
    idOf: (collection) => collection.id,
    nameOf: (collection) => collection.name,
    countTextOf: (collection) => '${collection.itemCount} 个视频',
    excludedCollectionId: excludedCollectionId,
    onCreate: (context, isDrawer) => showVideoCollectionDialog(
      context,
      presentation: isDrawer
          ? VideoCollectionEditPresentation.bottomDrawer
          : VideoCollectionEditPresentation.dialog,
    ),
  );
}

AppAdaptiveModalVariant _variantOf(
  PickVideoCollectionPresentation presentation,
) {
  return switch (presentation) {
    PickVideoCollectionPresentation.dialog => AppAdaptiveModalVariant.dialog,
    PickVideoCollectionPresentation.bottomDrawer =>
      AppAdaptiveModalVariant.drawer,
  };
}
