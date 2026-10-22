import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/language/app_language.dart';
import 'package:sakuramedia/app/language/providers/language_providers.dart';
import 'package:sakuramedia/app/providers/riverpod_page_cache_provider.dart';
import 'package:sakuramedia/core/network/api_error_localizations.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_api_provider.dart';
import 'package:sakuramedia/features/plugins/presentation/providers/plugins_provider.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_settings_group.dart';

/// 界面语言设置：保存到后端与本机，切换后立即使 UI 生效。
class LanguageSettingsContent extends ConsumerStatefulWidget {
  const LanguageSettingsContent({super.key});

  @override
  ConsumerState<LanguageSettingsContent> createState() =>
      _LanguageSettingsContentState();
}

class _LanguageSettingsContentState
    extends ConsumerState<LanguageSettingsContent> {
  bool _isSaving = false;

  Future<void> _select(AppLanguage language) async {
    if (_isSaving || ref.read(appLanguageControllerProvider) == language) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      final account = await ref
          .read(accountApiProvider)
          .updateLanguage(language.apiTag);
      final savedLanguage = AppLanguage.tryFromTag(account.language);
      if (savedLanguage != language) {
        if (mounted) {
          showToast(l10n.settingsLanguageUpdateFailed);
        }
        return;
      }
      await ref
          .read(appLanguageControllerProvider.notifier)
          .setLanguage(language);
      if (!mounted) {
        return;
      }
      // 插件列表/插件设置标题是服务端读时文案，切换后需要重新拉取。
      ref.invalidate(pluginsProvider);
      ref.read(riverpodPageCacheProvider).clearAll();
    } catch (error) {
      if (mounted) {
        showToast(
          localizedApiErrorMessage(
            l10n,
            error,
            fallback: l10n.settingsLanguageUpdateFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.appSpacing;
    final current = ref.watch(appLanguageControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsLanguageTitle,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.medium,
          ),
        ),
        SizedBox(height: spacing.sm),
        AppSettingsGroup(
          footer: l10n.settingsLanguageHint,
          children: [
            for (final language in AppLanguage.values)
              AppSettingCell(
                key: Key('settings-language-${language.apiTag}'),
                icon: Icons.translate_rounded,
                title: _label(l10n, language),
                trailing: current == language
                    ? Icon(
                        Icons.check_circle_rounded,
                        size: context.appComponentTokens.iconSizeMd,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: _isSaving ? null : () => unawaited(_select(language)),
              ),
          ],
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.zhCN => l10n.settingsLanguageSimplifiedChinese,
      AppLanguage.en => l10n.settingsLanguageEnglish,
    };
  }
}
