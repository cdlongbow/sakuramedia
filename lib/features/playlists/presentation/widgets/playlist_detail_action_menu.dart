import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';

enum PlaylistDetailActionType { edit, delete }

/// 播放列表详情「···」菜单：编辑信息 / 删除播放列表。
///
/// 触发方式均为上下文入口——桌面 hover「···」按钮、桌面右键 / 移动长按横幅，
/// 统一使用锚定按压点的 [AppMenuPresentation.popup]。
Future<PlaylistDetailActionType?> showPlaylistDetailActionMenu({
  required BuildContext context,
  required PlaylistDto playlist,
  required Offset position,
}) {
  return showAppActionMenu<PlaylistDetailActionType>(
    context: context,
    globalPosition: position,
    presentation: AppMenuPresentation.popup,
    useRootNavigator: true,
    items: <AppMenuItem<PlaylistDetailActionType>>[
      if (playlist.isMutable)
        const AppMenuItem(
          key: Key('playlist-detail-action-edit'),
          value: PlaylistDetailActionType.edit,
          label: '编辑信息',
          icon: Icons.edit_outlined,
        ),
      if (playlist.isDeletable)
        const AppMenuItem(
          key: Key('playlist-detail-action-delete'),
          value: PlaylistDetailActionType.delete,
          label: '删除播放列表',
          icon: Icons.delete_outline_rounded,
          tone: AppTextTone.error,
        ),
    ],
  );
}
