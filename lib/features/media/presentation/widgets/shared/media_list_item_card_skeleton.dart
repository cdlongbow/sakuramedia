import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_left_cover_card_skeleton.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';

/// [MediaListItemCard] 的骨架列表：复用 [AppLeftCoverCardSkeletonList] 的卡片壳，
/// 封面宽度 / 最小高度取自同一组 `listRowCover*` token，数据到达时列表不整片跳变。
///
/// 右侧内容行对齐真实卡的行结构（标题 / 副标题 / 元数据 / 文件名）。
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
    final tokens = context.appComponentTokens;
    return AppLeftCoverCardSkeletonList(
      coverWidth: tokens.listRowCoverWidth,
      bodyMinHeight: tokens.listRowCoverHeight,
      bodyPadding: EdgeInsets.symmetric(
        horizontal: context.appSpacing.lg,
        vertical: context.appSpacing.md,
      ),
      itemSpacing: itemSpacing,
      body: const _MediaCardSkeletonBody(),
    );
  }
}

class _MediaCardSkeletonBody extends StatelessWidget {
  const _MediaCardSkeletonBody();

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSkeletonBlock(width: 160, height: 16),
        SizedBox(height: spacing.sm),
        const AppSkeletonBlock(width: 220, height: 12),
        SizedBox(height: spacing.xs),
        const AppSkeletonBlock(width: 200, height: 12),
        SizedBox(height: spacing.sm),
        const AppSkeletonBlock(width: 140, height: 12),
      ],
    );
  }
}
