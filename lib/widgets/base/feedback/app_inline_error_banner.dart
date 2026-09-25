import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';

/// 内联错误提示条：错误图标 + 说明文字 + 重试按钮。
///
/// 用于「某段数据加载失败但仍可继续使用页面」的场景，例如榜单筛选元数据
/// 加载失败。整块内容不可用的错误用 `AppSectionError` / `AppEmptyState`。
class AppInlineErrorBanner extends StatelessWidget {
  const AppInlineErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.appSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: context.appComponentTokens.iconSizeXl,
              color: context.appTextPalette.secondary,
            ),
            SizedBox(width: context.appSpacing.sm),
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
            SizedBox(width: context.appSpacing.sm),
            AppButton(
              label: '重试',
              size: AppButtonSize.xSmall,
              variant: AppButtonVariant.secondary,
              onPressed: () => unawaited(onRetry()),
            ),
          ],
        ),
      ),
    );
  }
}
