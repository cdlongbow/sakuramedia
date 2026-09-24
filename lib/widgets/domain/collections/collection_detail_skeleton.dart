import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_cover_card_skeleton.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';
import 'package:sakuramedia/widgets/base/layout/grids/grid_column_resolver.dart';

/// 合集详情（切片 / 时刻）桌面首屏骨架：标题行 + 工具条 + 封面网格。
///
/// 列数复用 [resolveGridColumnCount]，与真实网格一致（此前骨架按
/// `maxCrossAxisExtent` 算出的列数比真实网格多一列，数据到达时会跳一下）。
class CollectionDetailSkeleton extends StatelessWidget {
  const CollectionDetailSkeleton({
    super.key,
    this.contentKey,
    this.gridKey,
    this.placeholderCount = 8,
  });

  final Key? contentKey;
  final Key? gridKey;
  final int placeholderCount;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      key: contentKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppSkeletonBlock(width: 196, height: 24),
            const Spacer(),
            AppSkeletonBlock(
              width: 84,
              height: context.appComponentTokens.buttonHeightSm,
              radius: context.appRadius.pillBorder,
            ),
          ],
        ),
        SizedBox(height: spacing.md),
        Row(
          children: [
            AppSkeletonBlock(
              width: 96,
              height: context.appComponentTokens.buttonHeightXs,
              radius: context.appRadius.pillBorder,
            ),
            SizedBox(width: spacing.sm),
            const AppSkeletonBlock(width: 68, height: 14),
            const Spacer(),
            AppSkeletonBlock(
              width: context.appComponentTokens.buttonHeightSm,
              height: context.appComponentTokens.buttonHeightSm,
              radius: context.appRadius.mdBorder,
            ),
          ],
        ),
        SizedBox(height: spacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = resolveGridColumnCount(
                width: constraints.maxWidth,
                spacing: spacing.md,
                targetWidth: 280,
                maxColumns: 4,
              );
              return GridView.builder(
                key: gridKey,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing.md,
                  crossAxisSpacing: spacing.md,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: placeholderCount,
                itemBuilder: (_, _) => const AppCoverCardSkeleton(),
              );
            },
          ),
        ),
      ],
    );
  }
}
