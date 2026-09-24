import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_mobile_skeleton.dart';

/// 选择器选项行的首屏骨架：复选框位 + 72×16:9 封面 + 两行文案，
/// 与选择器选项行（封面形态）同形，避免数据到达时列表整体跳变。
class AppPickerOptionSkeletonList extends StatelessWidget {
  const AppPickerOptionSkeletonList({super.key});

  static const int _placeholderCount = 4;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      children: List<Widget>.generate(_placeholderCount, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: context.appRadius.xsBorder,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: AppSkeletonBlock(
                        width: 20,
                        height: 20,
                        radius: context.appRadius.xsBorder,
                      ),
                    ),
                  ),
                  AppSkeletonBlock(
                    width: 72,
                    height: 72 * 9 / 16,
                    radius: context.appRadius.xsBorder,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSkeletonBlock(width: 120, height: 14),
                        SizedBox(height: spacing.xs),
                        const AppSkeletonBlock(width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
