import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/format/updated_at_label.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/account/data/account_dto.dart';
import 'package:sakuramedia/features/account/presentation/account_placeholders.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_api_provider.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_profile_provider.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_profile_state.dart';
import 'package:sakuramedia/features/account/presentation/providers/api_keys_provider.dart';
import 'package:sakuramedia/features/auth/presentation/providers/auth_api_provider.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_inline_spinner.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/forms/app_password_field.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_content_card.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/domain/account/api_key_generate_panel.dart';

/// 移动端「账号安全」：账号资料与用户名、修改密码、API 密钥集中一页。
class MobileAccountSecurityPage extends ConsumerStatefulWidget {
  const MobileAccountSecurityPage({super.key});

  @override
  ConsumerState<MobileAccountSecurityPage> createState() =>
      _MobileAccountSecurityPageState();
}

class _MobileAccountSecurityPageState
    extends ConsumerState<MobileAccountSecurityPage> {
  final GlobalKey<FormState> _usernameFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _hasAttemptedUsernameSubmit = false;
  bool _hasAttemptedPasswordSubmit = false;
  bool _hasSyncedInitialUsername = false;
  bool _isSubmittingPassword = false;

  AutovalidateMode get _usernameAutovalidateMode => _hasAttemptedUsernameSubmit
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  AutovalidateMode get _passwordAutovalidateMode => _hasAttemptedPasswordSubmit
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 首次拉到 account 后把 username 灌进输入框（只灌一次，用户已开始改动时不覆盖）。
  void _syncInitialUsername(AccountProfileState state) {
    if (_hasSyncedInitialUsername) return;
    final account = state.account;
    if (account == null) return;
    _hasSyncedInitialUsername = true;
    _usernameController.text = account.username;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final profileState = ref.watch(accountProfileProvider);
    _syncInitialUsername(profileState);

    return ListView(
      key: const Key('mobile-settings-account-security'),
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.md,
        spacing.lg,
      ),
      children: [
        _buildAccountCard(context, profileState),
        SizedBox(height: spacing.xl),
        _buildPasswordCard(context),
        SizedBox(height: spacing.xl),
        _buildApiKeysCard(context),
      ],
    );
  }

  // ===== 账号资料与用户名 =====

  Widget _buildAccountCard(
    BuildContext context,
    AccountProfileState profileState,
  ) {
    final spacing = context.appSpacing;
    final account = profileState.account;
    final showSkeleton = profileState.isLoading && account == null;
    final displayAccount = showSkeleton ? accountPlaceholder() : account;
    final canSubmitUsername =
        !profileState.isLoading && !profileState.isSaving && account != null;

    return AppContentCard(
      key: const Key('mobile-account-card'),
      title: '账号',
      padding: EdgeInsets.all(spacing.md),
      child: AppSkeletonizer(
        enabled: showSkeleton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (profileState.errorMessage != null && account == null)
              AppEmptyState(
                message: profileState.errorMessage!,
                retryKey: const Key('mobile-account-retry-button'),
                onRetry: () => ref.read(accountProfileProvider.notifier).load(),
              )
            else ...[
              if (displayAccount != null) ...[
                _AccountInfoRow(label: '用户名', value: displayAccount.username),
                SizedBox(height: spacing.sm),
                _AccountInfoRow(
                  label: '创建时间',
                  value: formatUpdatedAtLabel(displayAccount.createdAt) ?? '未知',
                ),
                SizedBox(height: spacing.sm),
                _AccountInfoRow(
                  label: '上次登录',
                  value:
                      formatUpdatedAtLabel(displayAccount.lastLoginAt) ?? '未知',
                ),
                SizedBox(height: spacing.md),
                Divider(height: 1, color: context.appColors.divider),
                SizedBox(height: spacing.md),
              ],
              Form(
                key: _usernameFormKey,
                autovalidateMode: _usernameAutovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      fieldKey: const Key('mobile-account-username-field'),
                      controller: _usernameController,
                      label: '用户名',
                      hintText: '请输入新的用户名',
                      helperText: '保存后当前登录态保持不变。',
                      enabled: !profileState.isSaving,
                      validator: _validateUsername,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitUsername(),
                    ),
                    if (profileState.errorMessage != null &&
                        account != null) ...[
                      SizedBox(height: spacing.sm),
                      Text(
                        profileState.errorMessage!,
                        key: const Key('mobile-account-username-error-text'),
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s12,
                          tone: AppTextTone.error,
                        ),
                      ),
                    ],
                    SizedBox(height: spacing.lg),
                    AppButton(
                      key: const Key('mobile-account-username-submit-button'),
                      label: '保存用户名',
                      variant: AppButtonVariant.primary,
                      isLoading: profileState.isSaving,
                      onPressed: canSubmitUsername ? _submitUsername : null,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitUsername() async {
    final notifier = ref.read(accountProfileProvider.notifier);
    if (ref.read(accountProfileProvider).isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_hasAttemptedUsernameSubmit) {
      setState(() {
        _hasAttemptedUsernameSubmit = true;
      });
    }

    if (!(_usernameFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final saved = await notifier.saveUsername(_usernameController.text);
    if (!mounted) {
      return;
    }
    final state = ref.read(accountProfileProvider);
    if (saved) {
      _usernameController.text = state.account?.username ?? '';
      showToast('用户名已更新');
      return;
    }

    final message = state.errorMessage;
    if (message != null && message.isNotEmpty) {
      showToast(message);
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入用户名';
    }
    return null;
  }

  // ===== 修改密码 =====

  Widget _buildPasswordCard(BuildContext context) {
    final spacing = context.appSpacing;

    return AppContentCard(
      key: const Key('mobile-account-password-card'),
      title: '修改密码',
      padding: EdgeInsets.all(spacing.md),
      child: Form(
        key: _passwordFormKey,
        autovalidateMode: _passwordAutovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '修改密码后将立即退出当前登录，需要使用新密码重新登录。',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.muted,
              ),
            ),
            SizedBox(height: spacing.md),
            AppPasswordField(
              fieldKey: const Key('mobile-account-password-current-field'),
              visibilityButtonKey: const Key(
                'mobile-account-password-current-visibility-toggle',
              ),
              controller: _currentPasswordController,
              label: '当前密码',
              enabled: !_isSubmittingPassword,
              validator: _validateCurrentPassword,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: spacing.md),
            AppPasswordField(
              fieldKey: const Key('mobile-account-password-new-field'),
              visibilityButtonKey: const Key(
                'mobile-account-password-new-visibility-toggle',
              ),
              controller: _newPasswordController,
              label: '新密码',
              enabled: !_isSubmittingPassword,
              validator: _validateNewPassword,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: spacing.md),
            AppPasswordField(
              fieldKey: const Key('mobile-account-password-confirm-field'),
              visibilityButtonKey: const Key(
                'mobile-account-password-confirm-visibility-toggle',
              ),
              controller: _confirmPasswordController,
              label: '确认新密码',
              enabled: !_isSubmittingPassword,
              validator: _validateConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitPassword(),
            ),
            SizedBox(height: spacing.lg),
            AppButton(
              key: const Key('mobile-account-password-submit-button'),
              label: '确认修改',
              variant: AppButtonVariant.primary,
              isLoading: _isSubmittingPassword,
              onPressed: _isSubmittingPassword ? null : _submitPassword,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPassword() async {
    if (_isSubmittingPassword) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_hasAttemptedPasswordSubmit) {
      setState(() {
        _hasAttemptedPasswordSubmit = true;
      });
    }

    if (!(_passwordFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmittingPassword = true;
    });

    try {
      final accountApi = ref.read(accountApiProvider);
      final authApi = ref.read(authApiProvider);
      final cachedAccount = ref.read(accountProfileProvider).account;
      final username = (cachedAccount?.username.trim().isNotEmpty ?? false)
          ? cachedAccount!.username.trim()
          : (await accountApi.getAccount()).username.trim();

      await accountApi.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      try {
        await authApi.login(
          username: username,
          password: _newPasswordController.text.trim(),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        showToast('密码已修改，但新密码登录校验失败，请重新登录确认');
        return;
      }

      if (!mounted) {
        return;
      }
      showToast('密码已更新，请重新登录');
      await context.logOut();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showToast(apiErrorMessage(error, fallback: '修改密码失败'));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingPassword = false;
        });
      }
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入当前密码';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final nextPassword = value?.trim() ?? '';
    if (nextPassword.isEmpty) {
      return '请输入新密码';
    }
    if (nextPassword == _currentPasswordController.text.trim()) {
      return '新密码不能与当前密码相同';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';
    if (confirmPassword.isEmpty) {
      return '请再次输入新密码';
    }
    if (confirmPassword != _newPasswordController.text.trim()) {
      return '两次输入的新密码不一致';
    }
    return null;
  }

  // ===== API 密钥 =====

  Widget _buildApiKeysCard(BuildContext context) {
    final spacing = context.appSpacing;
    final asyncKeys = ref.watch(apiKeysProvider);
    final keys = asyncKeys.value ?? const <ApiKeyDto>[];
    final showInitialLoading = asyncKeys.isLoading && !asyncKeys.hasValue;

    return AppContentCard(
      key: const Key('mobile-account-apikeys-card'),
      title: 'API 密钥',
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '供外部工具（如 MCP 服务）调用 API，权限等同于账号。密钥只在生成时显示一次，请妥善保存。',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.muted,
            ),
          ),
          SizedBox(height: spacing.md),
          if (showInitialLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.lg),
              child: const Center(child: AppInlineSpinner()),
            )
          else if (asyncKeys.hasError && !asyncKeys.hasValue)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  apiErrorMessage(asyncKeys.error!, fallback: 'API 密钥加载失败'),
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    tone: AppTextTone.error,
                  ),
                ),
                SizedBox(height: spacing.sm),
                AppButton(
                  key: const Key('mobile-account-apikeys-retry-button'),
                  label: '重试',
                  size: AppButtonSize.small,
                  onPressed: () => ref.invalidate(apiKeysProvider),
                ),
              ],
            )
          else if (keys.isEmpty)
            Text(
              '还没有 API 密钥。',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.muted,
              ),
            )
          else
            for (var index = 0; index < keys.length; index++) ...[
              if (index > 0)
                Divider(height: 1, color: context.appColors.divider),
              _buildApiKeyRow(context, keys[index]),
            ],
          SizedBox(height: spacing.lg),
          AppButton(
            key: const Key('mobile-account-apikeys-create-button'),
            label: '生成新密钥',
            variant: AppButtonVariant.secondary,
            icon: const Icon(Icons.add_rounded),
            onPressed: _openGenerateDrawer,
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyRow(BuildContext context, ApiKeyDto key) {
    final spacing = context.appSpacing;
    final title = key.name.isEmpty ? '未命名密钥' : key.name;
    final lastUsed = key.lastUsedAt == null
        ? '从未使用'
        : '最后使用 ${formatUpdatedAtLabel(key.lastUsedAt)}';
    final subtitle = '${key.keyHint} · $lastUsed';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                SizedBox(height: spacing.xs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    tone: AppTextTone.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          AppIconButton(
            key: Key('mobile-account-apikey-delete-${key.id}'),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '删除',
            onPressed: () => _deleteApiKey(key),
          ),
        ],
      ),
    );
  }

  Future<void> _openGenerateDrawer() async {
    await showAppBottomDrawer<void>(
      context: context,
      drawerKey: const Key('mobile-api-key-generate-drawer'),
      maxHeightFactor: 0.6,
      builder: (sheetContext) => const ApiKeyGeneratePanel(keyPrefix: 'mobile'),
    );
  }

  Future<void> _deleteApiKey(ApiKeyDto key) async {
    final label = key.name.isEmpty ? key.keyHint : key.name;
    final confirmed = await showAppConfirmDialog(
      context,
      title: '删除 API 密钥',
      message: '删除后使用「$label」的集成将立即失效，确认删除？',
      confirmLabel: '删除',
      danger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await ref.read(apiKeysProvider.notifier).delete(key.id);
    } catch (error) {
      if (mounted) {
        showToast(apiErrorMessage(error, fallback: '删除密钥失败'));
      }
    }
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.muted,
          ),
        ),
        SizedBox(width: context.appSpacing.md),
        Expanded(
          child: Text(
            value,
            key: Key('mobile-account-summary-$label'),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.medium,
              tone: AppTextTone.primary,
            ),
          ),
        ),
      ],
    );
  }
}
