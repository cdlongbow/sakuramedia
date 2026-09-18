import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_left_cover_card.dart';

/// [AppLeftCoverCard] 的骨架形态：复用同一卡片壳（圆角、细边、封面宽度、
/// 最小高度、内容内边距），左封面槽铺 `surfaceMuted` 灰块，右侧内容行用
/// [AppSkeletonBlock] 占位。
///
/// 与 [AppCoverCardSkeleton] 对偶。首屏骨架必须与真实卡同高同形，否则数据
/// 到达时列表会整片跳变；[body] 不传时是通用的三行灰条，行内含底部操作行等
/// 固定结构时由调用方传入行布局，配合 [bodyMinHeight] 对齐真实高度。
class AppLeftCoverCardSkeleton extends StatelessWidget {
  const AppLeftCoverCardSkeleton({
    super.key,
    required this.coverWidth,
    this.bodyMinHeight,
    this.bodyPadding,
    this.body,
  });

  final double coverWidth;
  final double? bodyMinHeight;
  final EdgeInsetsGeometry? bodyPadding;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return AppLeftCoverCard(
      coverWidth: coverWidth,
      bodyMinHeight: bodyMinHeight,
      bodyPadding: bodyPadding,
      cover: const AppSkeletonBlock(radius: BorderRadius.zero),
      body: body ?? const _DefaultSkeletonBody(),
    );
  }
}

/// 等距堆叠 [itemCount] 张 [AppLeftCoverCardSkeleton]，间距对齐真实列表的
/// `itemSpacing`（默认 `spacing.sm`）。
class AppLeftCoverCardSkeletonList extends StatelessWidget {
  const AppLeftCoverCardSkeletonList({
    super.key,
    required this.coverWidth,
    this.bodyMinHeight,
    this.bodyPadding,
    this.body,
    this.itemCount = 3,
    this.itemSpacing,
  });

  final double coverWidth;
  final double? bodyMinHeight;
  final EdgeInsetsGeometry? bodyPadding;
  final Widget? body;
  final int itemCount;
  final double? itemSpacing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      children: List<Widget>.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: itemSpacing ?? spacing.sm),
          child: AppLeftCoverCardSkeleton(
            coverWidth: coverWidth,
            bodyMinHeight: bodyMinHeight,
            bodyPadding: bodyPadding,
            body: body,
          ),
        ),
      ),
    );
  }
}

class _DefaultSkeletonBody extends StatelessWidget {
  const _DefaultSkeletonBody();

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeletonBlock(width: 120, height: 16),
        SizedBox(height: spacing.sm),
        const AppSkeletonBlock(width: 200, height: 12),
        SizedBox(height: spacing.xs),
        const AppSkeletonBlock(width: 160, height: 12),
        SizedBox(height: spacing.xs),
        const AppSkeletonBlock(width: 180, height: 12),
      ],
    );
  }
}
