import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/providers/appearance_providers.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_settings_group.dart';

/// 外观设置的共用内容；移动与桌面使用同一份偏好读写逻辑。
class AppearanceSettingsContent extends ConsumerWidget {
  const AppearanceSettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final appearance = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);
    final isDark = appearance.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '调整界面明暗与主题色，设置保存在本机。',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.secondary,
          ),
        ),
        SizedBox(height: spacing.lg),
        Text(
          '主题模式',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.medium,
          ),
        ),
        SizedBox(height: spacing.sm),
        AppSettingsGroup(
          children: [
            AppSettingCell(
              key: const Key('appearance-mode-light'),
              icon: Icons.light_mode_outlined,
              title: '浅色',
              trailing: isDark ? null : const _SelectionCheckMark(),
              onTap: () =>
                  unawaited(controller.setBrightness(Brightness.light)),
            ),
            AppSettingCell(
              key: const Key('appearance-mode-dark'),
              icon: Icons.dark_mode_outlined,
              title: '深色',
              trailing: isDark ? const _SelectionCheckMark() : null,
              onTap: () => unawaited(controller.setBrightness(Brightness.dark)),
            ),
          ],
        ),
        SizedBox(height: spacing.xl),
        Text(
          '主题色',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.medium,
          ),
        ),
        SizedBox(height: spacing.sm),
        AppSettingsGroup(
          footer: '主题色会应用到按钮、选中态和强调元素。',
          children: [
            for (final themeColor in AppThemeColor.values)
              AppSettingCell(
                key: Key('appearance-theme-color-${themeColor.id}'),
                title: themeColor.label,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemeColorSwatch(
                      color: themeColor
                          .forBrightness(appearance.brightness)
                          .primary,
                    ),
                    if (appearance.themeColor.id == themeColor.id) ...[
                      SizedBox(width: spacing.sm),
                      const _SelectionCheckMark(),
                    ],
                  ],
                ),
                onTap: () => unawaited(controller.setThemeColor(themeColor)),
              ),
          ],
        ),
      ],
    );
  }
}

class _ThemeColorSwatch extends StatelessWidget {
  const _ThemeColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = context.appComponentTokens.iconSizeLg;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.appColors.borderSubtle),
      ),
    );
  }
}

class _SelectionCheckMark extends StatelessWidget {
  const _SelectionCheckMark();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check_circle_rounded,
      size: context.appComponentTokens.iconSizeMd,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
