import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

/// 选择器选项行：左勾选框 + 可选封面 + 文案。
///
/// 两种形态用命名构造区分，不做配置开关：
/// - [AppPickerOptionTile.cover]：72×16:9 封面 + 标题/副标题（切片、时刻条目）；
/// - [AppPickerOptionTile.text]：单行标题 + 右侧计数（合集条目）。
///
/// [optionKey] 挂在整行可点区域、[checkboxKey] 挂在 `Checkbox` 上，沿用各弹窗
/// 既有测试锚点。勾选框统一缩到 0.85，避免 48dp 命中区把行撑高。
class AppPickerOptionTile extends StatelessWidget {
  const AppPickerOptionTile.cover({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.coverUrl,
    this.enabled = true,
    this.optionKey,
    this.checkboxKey,
  }) : trailingText = null,
       _isCover = true;

  const AppPickerOptionTile.text({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    this.trailingText,
    this.enabled = true,
    this.optionKey,
    this.checkboxKey,
  }) : subtitle = null,
       coverUrl = null,
       _isCover = false;

  static const double _checkboxScale = 0.85;
  static const double _coverWidth = 72;

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final String? coverUrl;

  /// `false` 时整行只读（请求进行中），勾选框与点击一起禁用。
  final bool enabled;

  final Key? optionKey;
  final Key? checkboxKey;

  final bool _isCover;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final subtitleText = subtitle?.trim();
    final trailing = trailingText?.trim();

    return AppInteractiveSurface(
      key: optionKey,
      enabled: enabled,
      onTap: onTap,
      child: Container(
        padding: _isCover
            ? EdgeInsets.all(spacing.xs)
            : EdgeInsets.symmetric(horizontal: spacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: context.appRadius.xsBorder,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Transform.scale(
              scale: _checkboxScale,
              child: Checkbox(
                key: checkboxKey,
                value: selected,
                onChanged: enabled ? (_) => onTap() : null,
              ),
            ),
            if (_isCover) ...[
              ClipRRect(
                borderRadius: context.appRadius.xsBorder,
                child: SizedBox(
                  width: _coverWidth,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildCover(colors),
                  ),
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s14,
                        weight: AppTextWeight.medium,
                        tone: AppTextTone.primary,
                      ),
                    ),
                    if (subtitleText != null && subtitleText.isNotEmpty) ...[
                      SizedBox(height: spacing.xs),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          weight: AppTextWeight.regular,
                          tone: AppTextTone.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s14,
                    weight: AppTextWeight.medium,
                    tone: AppTextTone.primary,
                  ),
                ),
              ),
              if (trailing != null && trailing.isNotEmpty)
                Text(
                  trailing,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.muted,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCover(AppColors colors) {
    final url = coverUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return MaskedImage(url: url, fit: BoxFit.cover);
    }
    return ColoredBox(color: colors.surfaceMuted);
  }
}
