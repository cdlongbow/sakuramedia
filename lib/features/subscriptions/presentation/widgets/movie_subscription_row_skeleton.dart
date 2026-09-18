import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_left_cover_card_skeleton.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';

/// 订阅管理页首屏骨架：与 [MovieSubscriptionRow] 同壳同高。
///
/// 行内容对齐真实卡的行结构（番号 + 标题 + 状态徽标 / 查询进度 / 底部操作行），
/// 底部 44px 操作行保证单卡高度与真实卡一致（约 148px），加载完成时列表不跳变。
class MovieSubscriptionListSkeleton extends StatelessWidget {
  const MovieSubscriptionListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    return AppLeftCoverCardSkeletonList(
      coverWidth: tokens.subscriptionRowCoverWidth,
      bodyMinHeight: tokens.subscriptionRowMinHeight,
      bodyPadding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.md,
      ),
      body: const _SubscriptionRowSkeletonBody(),
    );
  }
}

class _SubscriptionRowSkeletonBody extends StatelessWidget {
  const _SubscriptionRowSkeletonBody();

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final radius = context.appRadius.smBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeletonBlock(width: 64, height: 20),
                  SizedBox(height: spacing.xs),
                  const AppSkeletonBlock(width: 180, height: 18),
                ],
              ),
            ),
            SizedBox(width: spacing.sm),
            const AppSkeletonBlock(width: 47, height: 18),
          ],
        ),
        SizedBox(height: spacing.md),
        const AppSkeletonBlock(width: 120, height: 18),
        SizedBox(height: spacing.sm),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: const AppSkeletonBlock(width: 160, height: 18),
                ),
              ),
              AppSkeletonBlock(width: 44, height: 44, radius: radius),
              SizedBox(width: spacing.sm),
              AppSkeletonBlock(width: 44, height: 44, radius: radius),
            ],
          ),
        ),
      ],
    );
  }
}
