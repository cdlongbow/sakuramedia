import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';

/// [MediaFileGroupCard] 的骨架形态：同一分组卡壳（白底、圆角、细边、阴影），
/// 顶部封面块 + 标题区灰条，底部 [fileCount] 行文件行灰条（每行前保留
/// `Divider(height: spacing.xl)` 的节奏）。
///
/// 数据到达后每组的文件行数量由真实数据决定，骨架按常见的两行文件占位，
/// 保证首屏是「分组卡」而不是一组细线。
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
    final coverWidth = mobile
        ? tokens.movieDetailPlotThumbnailWidth
        : tokens.downloadTaskCoverWidth;
    final coverHeight = mobile
        ? tokens.movieDetailPlotThumbnailHeight
        : tokens.mediaManagementRowHeight;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: context.appRadius.lgBorder,
        border: Border.all(color: context.appColors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBlock(
                width: coverWidth,
                height: coverHeight,
                radius: BorderRadius.zero,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSkeletonBlock(width: 200, height: 16),
                      SizedBox(height: spacing.sm),
                      const AppSkeletonBlock(width: 160, height: 16),
                      SizedBox(height: spacing.sm),
                      const AppSkeletonBlock(width: 64, height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < fileCount; index++)
                  _FileRowSkeleton(mobile: mobile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileRowSkeleton extends StatelessWidget {
  const _FileRowSkeleton({required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeletonBlock(width: 160, height: 20),
        SizedBox(height: spacing.sm),
        const AppSkeletonBlock(width: 220, height: 16),
      ],
    );
    const deleteButton = AppSkeletonBlock(width: 88, height: 32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: spacing.xl, color: context.appColors.divider),
        if (mobile) ...[
          content,
          SizedBox(height: spacing.md),
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: deleteButton,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              SizedBox(width: spacing.lg),
              deleteButton,
            ],
          ),
      ],
    );
  }
}
