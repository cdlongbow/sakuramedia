import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/format/updated_at_label.dart';
import 'package:sakuramedia/features/account/data/account_dto.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_profile_provider.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_profile_state.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_notice_card.dart';

class MobileChangeUsernamePage extends ConsumerStatefulWidget {
  const MobileChangeUsernamePage({super.key});

  @override
  ConsumerState<MobileChangeUsernamePage> createState() =>
      _MobileChangeUsernamePageState();
}

class _MobileChangeUsernamePageState
    extends ConsumerState<MobileChangeUsernamePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final FocusNode _usernameFocusNode;
  bool _hasAttemptedSubmit = false;
  bool _hasSyncedInitialUsername = false;

  AutovalidateMode get _autovalidateMode =>
      _hasAttemptedSubmit
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController()..addListener(_handleInputChanged);
    _usernameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _usernameController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 首次拉到 account 后把 username 灌进输入框（只灌一次，用户已开始改动时不覆盖）。
  void _syncInitialUsername(AccountProfileState state) {
    if (_hasSyncedInitialUsername) return;
    final account = state.account;
    if (account == null) return;
    _hasSyncedInitialUsername = true;
    _usernameController.text = account.username;
  }

  Future<void> _submit() async {
    final notifier = ref.read(accountProfileProvider.notifier);
    if (ref.read(accountProfileProvider).isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_hasAttemptedSubmit) {
      setState(() {
        _hasAttemptedSubmit = true;
      });
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountProfileProvider);
    _syncInitialUsername(state);

    final spacing = context.appSpacing;
    final colors = context.appColors;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final canSubmit =
        !state.isLoading && !state.isSaving && state.account != null;

    return ColoredBox(
      key: const Key('mobile-settings-username'),
      color: colors.surfaceCard,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.md,
                spacing.md,
                spacing.lg,
              ),
              child: _buildBody(context, state),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.md,
              spacing.md,
              spacing.md + viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                key: const Key('mobile-username-submit-button'),
                label: state.isSaving ? '保存中' : '保存用户名',
                variant: AppButtonVariant.primary,
                isLoading: state.isSaving,
                onPressed: canSubmit ? _submit : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AccountProfileState state) {
    final spacing = context.appSpacing;

    if (state.isLoading && state.account == null) {
      return const _MobileUsernameLoadingSection();
    }

    if (state.errorMessage != null && state.account == null) {
      return _MobileUsernameErrorSection(
        message: state.errorMessage!,
        onRetry: () => ref.read(accountProfileProvider.notifier).load(),
      );
    }

    final account = state.account;
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppNoticeCard(
            key: Key('mobile-username-notice-card'),
            leadingIcon: Icons.info_outline_rounded,
            description: '用户名会用于登录和账号识别，保存后当前登录态保持不变。',
          ),
          SizedBox(height: spacing.md),
          if (account != null) ...[
            _AccountSummaryCard(account: account),
            SizedBox(height: spacing.md),
          ],
          _FormCard(
            children: [
              AppTextField(
                fieldKey: const Key('mobile-username-field'),
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                label: '用户名',
                hintText: '请输入新的用户名',
                enabled: !state.isSaving,
                validator: _validateUsername,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (state.errorMessage != null && account != null) ...[
                SizedBox(height: spacing.sm),
                Text(
                  state.errorMessage!,
                  key: const Key('mobile-username-error-text'),
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    tone: AppTextTone.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileUsernameLoadingSection extends StatelessWidget {
  const _MobileUsernameLoadingSection();

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonBlock(height: 92, borderRadius: context.appRadius.mdBorder),
        SizedBox(height: spacing.md),
        _SkeletonBlock(height: 112, borderRadius: context.appRadius.lgBorder),
        SizedBox(height: spacing.md),
        _SkeletonBlock(height: 92, borderRadius: context.appRadius.lgBorder),
      ],
    );
  }
}

class _MobileUsernameErrorSection extends StatelessWidget {
  const _MobileUsernameErrorSection({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      children: [
        AppEmptyState(
          message: message,
          retryKey: const Key('mobile-username-retry-button'),
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({required this.account});

  final AccountDto account;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return _FormCard(
      key: const Key('mobile-username-summary-card'),
      children: [
        Text(
          '当前账号',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.semibold,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: spacing.md),
        _AccountInfoRow(label: '用户名', value: account.username),
        SizedBox(height: spacing.sm),
        _AccountInfoRow(
          label: '创建时间',
          value: formatUpdatedAtLabel(account.createdAt) ?? '未知',
        ),
        SizedBox(height: spacing.sm),
        _AccountInfoRow(
          label: '上次登录',
          value: formatUpdatedAtLabel(account.lastLoginAt) ?? '未知',
        ),
      ],
    );
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
            key: Key('mobile-username-summary-$label'),
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

class _FormCard extends StatelessWidget {
  const _FormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key == null ? const Key('mobile-username-form-card') : null,
      padding: EdgeInsets.all(context.appSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: context.appRadius.lgBorder,
        border: Border.all(color: context.appColors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, required this.borderRadius});

  final double height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: borderRadius,
      ),
    );
  }
}
