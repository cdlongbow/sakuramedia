import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_left_cover_card_skeleton.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';

/// [MediaListItemCard] 的骨架列表：封面宽度与最小高度和真实卡取自同一组
/// token，桌面固定行高、移动流式行高都能与加载后的列表对齐。
///
/// 移动端真实卡在底部有整宽的删除按钮，骨架补一个全宽占位行，避免卡片
/// 下部整片空白。
class MediaListItemCardSkeletonList extends StatelessWidget {
  const MediaListItemCardSkeletonList({
    super.key,
    required this.mobile,
    this.itemSpacing,
  });

  final bool mobile;
  final double? itemSpacing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    return AppLeftCoverCardSkeletonList(
      coverWidth: mobile
          ? tokens.mobileFollowMovieThinCoverWidth
          : tokens.downloadTaskCoverWidth,
      bodyMinHeight: mobile
          ? tokens.mobileFollowMovieCardHeight
          : tokens.mediaManagementRowHeight,
      bodyPadding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.md,
      ),
      itemSpacing: itemSpacing,
      body: mobile ? const _MobileCardSkeletonBody() : null,
    );
  }
}

class _MobileCardSkeletonBody extends StatelessWidget {
  const _MobileCardSkeletonBody();

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeletonBlock(width: 120, height: 16),
        SizedBox(height: spacing.sm),
        const AppSkeletonBlock(width: 180, height: 12),
        SizedBox(height: spacing.xs),
        const AppSkeletonBlock(width: 140, height: 12),
        SizedBox(height: spacing.sm),
        const AppSkeletonBlock(width: 100, height: 12),
        SizedBox(height: spacing.md),
        const AppSkeletonBlock(width: double.infinity, height: 36),
      ],
    );
  }
}

