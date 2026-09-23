import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_left_cover_card_skeleton.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';

/// [MediaFileGroupCard] 的骨架形态：单层卡 + 组头（贴边小缩略图块 + 标题区灰条）
/// + [fileCount] 行文件行灰条（行尾保留删除图标的占位）。
///
/// 与真实组卡同尺寸 token；数据到达后每组的文件行数量由真实数据决定，
/// 骨架按常见的两行文件占位，保证首屏是「分组卡」而不是一组细线。
class MediaFileGroupCardSkeleton extends StatelessWidget {
  const MediaFileGroupCardSkeleton({
    super.key,
    required this.mobile,
    this.fileCount = 2,
  });

  final bool mobile;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLeftCoverCardSkeleton(
            shell: false,
            coverWidth: tokens.listGroupHeaderCoverWidth,
            bodyMinHeight: tokens.listGroupHeaderCoverHeight,
            bodyPadding: EdgeInsets.all(mobile ? spacing.sm : spacing.md),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppSkeletonBlock(width: 160, height: 16),
                SizedBox(height: spacing.xs),
                const AppSkeletonBlock(width: 200, height: 12),
                SizedBox(height: spacing.sm),
                const AppSkeletonBlock(width: 64, height: 20),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md),
            child: Column(
              children: [
                for (var index = 0; index < fileCount; index++)
                  _FileRowSkeleton(index: index),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileRowSkeleton extends StatelessWidget {
  const _FileRowSkeleton({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      children: [
        if (index > 0)
          Divider(height: 1, thickness: 1, color: context.appColors.divider),
        Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSkeletonBlock(width: 160, height: 16),
                    SizedBox(height: spacing.sm),
                    const AppSkeletonBlock(width: 220, height: 12),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              AppSkeletonBlock(
                width: 28,
                height: 28,
                radius: context.appRadius.smBorder,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
