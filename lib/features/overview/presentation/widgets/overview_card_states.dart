import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';

/// 概览卡片的统一错误行：一行说明 + 重试文字按钮。
class OverviewCardErrorRow extends StatelessWidget {
  const OverviewCardErrorRow({
    super.key,
    required this.message,
    this.onRetry,
    this.retryKey,
  });

  final String message;
  final VoidCallback? onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.regular,
              tone: AppTextTone.secondary,
            ),
          ),
        ),
        if (onRetry != null) ...[
          SizedBox(width: context.appSpacing.sm),
          AppTextButton(
            label: '重试',
            size: AppTextButtonSize.small,
            labelKey: retryKey,
            onPressed: onRetry,
          ),
        ],
      ],
    );
  }
}

/// 概览卡片的通用骨架：若干条灰色圆角条。
class OverviewCardLoadingBars extends StatelessWidget {
  const OverviewCardLoadingBars({super.key, this.rows = 3, this.lastRowFraction = 0.6});

  final int rows;

  /// 最后一条的宽度占比，让骨架看起来像真实内容而不是整齐的输入框。
  final double lastRowFraction;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var index = 0; index < rows; index += 1) ...<Widget>[
          if (index > 0) SizedBox(height: spacing.md),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: index == rows - 1 ? lastRowFraction : 1,
            child: Container(
              height: spacing.md,
              decoration: BoxDecoration(
                color: context.appColors.borderSubtle,
                borderRadius: context.appRadius.pillBorder,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
