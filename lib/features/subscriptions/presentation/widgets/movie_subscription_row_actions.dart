import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';

enum MovieSubscriptionRowAction {
  openDownloads,
  viewFiles,
  retriggerImport,
  searchMagnet,
  deleteDownloads,
  unsubscribe,
}

/// 移动端订阅卡片的「更多」底部操作表。
///
/// 行内不再摆一排无标签图标；这里用 图标 + 中文标签 + 一句说明 让每个动作
/// 自解释，危险动作（删任务 / 取消订阅）用红色文字。不满足条件的项直接隐藏。
/// 标题以番号为主、影片标题为次，让用户先确认"是哪部片"。
Future<MovieSubscriptionRowAction?> showMovieSubscriptionRowActions({
  required BuildContext context,
  required String movieNumber,
  required String movieTitle,
  required bool hasDownloads,
  required bool hasFiles,
  required bool canRetriggerImport,
}) {
  final number = movieNumber.trim();
  final title = movieTitle.trim();
  final primaryTitle = number.isNotEmpty ? number : title;
  final subtitle = title.isNotEmpty && title != primaryTitle ? title : null;
  return showAppActionMenu<MovieSubscriptionRowAction>(
    context: context,
    presentation: AppMenuPresentation.bottomDrawer,
    drawerKey: const Key('movie-subscription-row-actions'),
    title: primaryTitle,
    titleSubtitle: subtitle,
    items: <AppMenuItem<MovieSubscriptionRowAction>>[
      AppMenuItem(
        key: const Key('movie-subscription-row-action-downloads'),
        value: MovieSubscriptionRowAction.openDownloads,
        label: '查看下载任务',
        subtitle: '查看该影片的下载进度',
        icon: Icons.download_outlined,
        visible: hasDownloads,
      ),
      AppMenuItem(
        key: const Key('movie-subscription-row-action-files'),
        value: MovieSubscriptionRowAction.viewFiles,
        label: '查看文件',
        subtitle: '查看最新已完成任务里的文件',
        icon: Icons.folder_open_rounded,
        visible: hasFiles,
      ),
      AppMenuItem(
        key: const Key('movie-subscription-row-action-retrigger-import'),
        value: MovieSubscriptionRowAction.retriggerImport,
        label: '重新导入',
        subtitle: '重提最新失败或跳过的导入任务',
        icon: Icons.refresh_rounded,
        visible: canRetriggerImport,
      ),
      const AppMenuItem(
        key: Key('movie-subscription-row-action-magnet-search'),
        value: MovieSubscriptionRowAction.searchMagnet,
        label: '磁力搜索',
        subtitle: '手动搜索资源并提交下载',
        icon: Icons.search_rounded,
      ),
      AppMenuItem(
        key: const Key('movie-subscription-row-action-delete-downloads'),
        value: MovieSubscriptionRowAction.deleteDownloads,
        label: '删除下载任务',
        subtitle: '可选同时删除下载器里的文件',
        icon: Icons.delete_outline_rounded,
        tone: AppTextTone.error,
        visible: hasDownloads,
      ),
      const AppMenuItem(
        key: Key('movie-subscription-row-action-unsubscribe'),
        value: MovieSubscriptionRowAction.unsubscribe,
        label: '取消订阅',
        subtitle: '不再自动查找资源，不影响已有文件',
        icon: Icons.bookmark_remove_outlined,
        tone: AppTextTone.error,
      ),
    ],
  );
}
