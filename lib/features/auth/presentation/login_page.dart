import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/shell/window/app_windows_caption.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/language/app_language.dart';
import 'package:sakuramedia/app/language/providers/language_providers.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_api_provider.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/providers/credential_store_provider.dart';
import 'package:sakuramedia/features/auth/presentation/providers/auth_api_provider.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/app/providers/external_url_provider.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_notice_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.platform});

  final AppPlatform platform;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _baseUrlFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isSubmitting = false;
  bool _isPasswordObscured = true;
  bool _hasAttemptedSubmit = false;
  bool _languageTouched = false;
  String? _submitError;
  bool _showFirstRunNotice = false;
  bool _showDeployHelp = false;
  String _protocol = 'http';

  @override
  void initState() {
    super.initState();
    final savedBaseUrl = ref.read(sessionStoreProvider).baseUrl;
    _initBaseUrl(savedBaseUrl);
    _showFirstRunNotice = savedBaseUrl.trim().isEmpty;
    _loadSavedCredentials();
  }

  void _initBaseUrl(String savedBaseUrl) {
    final match = RegExp(r'^(https?)://').firstMatch(savedBaseUrl.trim());
    if (match != null) {
      _protocol = match.group(1)!;
      _baseUrlController.text = savedBaseUrl.trim().substring(match.end);
    } else {
      _baseUrlController.text = savedBaseUrl.trim();
    }
  }

  String _composeBaseUrl() => '$_protocol://${_baseUrlController.text.trim()}';

  Future<void> _loadSavedCredentials() async {
    final credentialStore = ref.read(credentialStoreProvider);
    final username = await credentialStore.readUsername();
    final password = await credentialStore.readPassword();
    if (!mounted) return;
    if (username != null && username.isNotEmpty) {
      _usernameController.text = username;
    }
    if (password != null && password.isNotEmpty) {
      _passwordController.text = password;
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _baseUrlFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_isSubmitting) {
      return;
    }

    if (!_hasAttemptedSubmit) {
      setState(() {
        _hasAttemptedSubmit = true;
      });
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _submitError = null;
      _showDeployHelp = false;
    });

    final sessionStore = ref.read(sessionStoreProvider);
    final authApi = ref.read(authApiProvider);
    final accountApi = ref.read(accountApiProvider);
    final selectedLanguage = ref.read(appLanguageControllerProvider);

    try {
      await sessionStore.saveBaseUrl(_composeBaseUrl());
      final tokens = await authApi.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (_languageTouched) {
        // 登录页的显式选择优先；保存失败不阻塞进入应用，设置页可重试。
        try {
          await accountApi.updateLanguage(selectedLanguage.apiTag);
        } catch (_) {
          // 语言已保存在本机，下一次切换/登录还会再次同步。
        }
      } else {
        await ref
            .read(appLanguageControllerProvider.notifier)
            .applyServerLanguage(tokens.user.language);
      }

      if (!mounted) {
        return;
      }
      context.go(overviewPathForPlatform(widget.platform));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = apiErrorMessage(
          error,
          fallback: l10n.loginErrorFallback,
          l10n: l10n,
        );
        _showDeployHelp = error.isTransportFailure;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = l10n.loginErrorNetwork;
        _showDeployHelp = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  static const _deployGuideUrl =
      'https://tinypinglite.github.io/sakuramedia/guide/quick-start';

  Future<void> _openDeployGuide() async {
    final l10n = AppLocalizations.of(context);
    final opened = await ref.read(externalUrlOpenerProvider)(
      Uri.parse(_deployGuideUrl),
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginOpenBrowserFailed)));
    }
  }

  void _dismissFirstRunNotice() {
    setState(() => _showFirstRunNotice = false);
  }

  String? _validateBaseUrl(AppLocalizations l10n, String? value) {
    final host = value?.trim() ?? '';
    if (host.isEmpty) {
      return l10n.loginServerRequired;
    }
    if (host.contains(RegExp(r'\s'))) {
      return l10n.loginServerInvalid;
    }

    final uri = Uri.tryParse('$_protocol://$host');
    if (uri == null || uri.host.isEmpty) {
      return l10n.loginServerInvalid;
    }
    return null;
  }

  /// 用户在地址框中粘贴/输入完整 URL（含协议）时，自动剥离协议前缀并切换下拉。
  void _handleBaseUrlChanged(String value) {
    final match = RegExp(r'^(https?)://').firstMatch(value);
    if (match == null) {
      return;
    }
    final scheme = match.group(1)!;
    final rest = value.substring(match.end);
    setState(() {
      _protocol = scheme;
    });
    _baseUrlController.value = TextEditingValue(
      text: rest,
      selection: TextSelection.collapsed(offset: rest.length),
    );
  }

  void _handleProtocolChanged(String protocol) {
    if (protocol == _protocol) {
      return;
    }
    setState(() {
      _protocol = protocol;
    });
  }

  String? _validateRequired(
    AppLocalizations l10n,
    String label,
    String? value,
  ) {
    if ((value ?? '').trim().isEmpty) {
      return l10n.loginFieldRequired(label);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLanguage = ref.watch(appLanguageControllerProvider);
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isCompact = MediaQuery.of(context).size.width < 640;

    return Scaffold(
      appBar: usesAppWindowsCaption
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                context.appComponentTokens.desktopTitleBarHeight,
              ),
              child: const AppWindowsCaption(standalone: true),
            )
          : null,
      backgroundColor: colors.surfacePage,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colors.surfacePage,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.18),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = isCompact ? spacing.lg : spacing.xxxl;
              // 横屏矮屏(如 VR 2D 面板)纵向空间紧张:收紧留白,尽量让整卡落在一屏内。
              final shortViewport = constraints.maxHeight < 400;
              final topPadding = shortViewport ? spacing.lg : spacing.xxl;
              final bottomPadding =
                  (shortViewport ? spacing.lg : spacing.xxl) +
                  viewInsets.bottom;
              final availableHeight =
                  constraints.maxHeight - topPadding - bottomPadding;
              // 矮屏下同步收紧:块级间距(副标题后/按钮前)、输入框间距、卡片内边距。
              final fieldGap = shortViewport ? spacing.sm : spacing.lg;
              final sectionGap = shortViewport ? spacing.md : spacing.xl;
              final cardPadding = shortViewport ? spacing.lg : spacing.xl;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, availableHeight),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        key: const Key('login-main-card'),
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: colors.surfaceCard.withValues(alpha: 0.94),
                          borderRadius: radius.lgBorder,
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _hasAttemptedSubmit
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  SizedBox(width: spacing.sm),
                                  Expanded(
                                    child: Text(
                                      'SakuraMedia',
                                      style: resolveAppTextStyle(
                                        context,
                                        size: AppTextSize.s18,
                                        weight: AppTextWeight.semibold,
                                      ),
                                    ),
                                  ),
                                  _LoginLanguageSwitcher(
                                    current: currentLanguage,
                                    enabled: !_isSubmitting,
                                    onSelected: (language) {
                                      setState(() {
                                        _languageTouched = true;
                                      });
                                      unawaited(
                                        ref
                                            .read(
                                              appLanguageControllerProvider
                                                  .notifier,
                                            )
                                            .setLanguage(language),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing.lg),
                              if (_showFirstRunNotice) ...[
                                AppNoticeCard(
                                  key: const Key('login-first-run-notice'),
                                  leadingIcon: Icons.dns_outlined,
                                  title: l10n.loginFirstRunTitle,
                                  description: l10n.loginFirstRunDescription,
                                ),
                                SizedBox(height: spacing.sm),
                                Wrap(
                                  spacing: spacing.sm,
                                  runSpacing: spacing.xs,
                                  children: <Widget>[
                                    AppTextButton(
                                      key: const Key('login-open-deploy-guide'),
                                      label: l10n.loginViewDeployGuide,
                                      icon: Icon(
                                        Icons.open_in_new_rounded,
                                        size: context
                                            .appComponentTokens
                                            .iconSizeSm,
                                      ),
                                      size: AppTextButtonSize.small,
                                      onPressed: _isSubmitting
                                          ? null
                                          : _openDeployGuide,
                                    ),
                                    AppTextButton(
                                      key: const Key('login-dismiss-first-run'),
                                      label: l10n.loginHaveServer,
                                      size: AppTextButtonSize.small,
                                      onPressed: _isSubmitting
                                          ? null
                                          : _dismissFirstRunNotice,
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing.lg),
                              ],
                              Text(
                                l10n.loginSubtitle,
                                style: resolveAppTextStyle(
                                  context,
                                  size: AppTextSize.s14,
                                  tone: AppTextTone.secondary,
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              AppTextField(
                                fieldKey: const Key('login-form-base-url'),
                                controller: _baseUrlController,
                                focusNode: _baseUrlFocusNode,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                enabled: !_isSubmitting,
                                validator: (value) =>
                                    _validateBaseUrl(l10n, value),
                                onChanged: _handleBaseUrlChanged,
                                onFieldSubmitted: (_) =>
                                    _usernameFocusNode.requestFocus(),
                                hintText: '127.0.0.1:38000',
                                prefix: _ProtocolPrefix(
                                  protocol: _protocol,
                                  enabled: !_isSubmitting,
                                  onChanged: _handleProtocolChanged,
                                ),
                                suffix: AppIconButton(
                                  key: const Key('login-base-url-help'),
                                  tooltip: l10n.loginServerHelpTooltip,
                                  padding: EdgeInsets.all(
                                    context.appSpacing.xs,
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : _openDeployGuide,
                                  icon: Icon(
                                    Icons.help_outline_rounded,
                                    size: context.appComponentTokens.iconSizeSm,
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing.xs),
                              Text(
                                l10n.loginServerHelper,
                                style: resolveAppTextStyle(
                                  context,
                                  size: AppTextSize.s12,
                                  tone: AppTextTone.muted,
                                ),
                              ),
                              SizedBox(height: fieldGap),
                              AppTextField(
                                fieldKey: const Key('login-form-username'),
                                controller: _usernameController,
                                focusNode: _usernameFocusNode,
                                textInputAction: TextInputAction.next,
                                enabled: !_isSubmitting,
                                validator: (value) => _validateRequired(
                                  l10n,
                                  l10n.loginUsername,
                                  value,
                                ),
                                onFieldSubmitted: (_) =>
                                    _passwordFocusNode.requestFocus(),
                                hintText: l10n.loginUsername,
                                prefix: Icon(
                                  Icons.person_outline_rounded,
                                  size: context.appComponentTokens.iconSizeMd,
                                  color: context.appTextPalette.muted,
                                ),
                              ),
                              SizedBox(height: fieldGap),
                              AppTextField(
                                fieldKey: const Key('login-form-password'),
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _isPasswordObscured,
                                textInputAction: TextInputAction.done,
                                enabled: !_isSubmitting,
                                validator: (value) => _validateRequired(
                                  l10n,
                                  l10n.loginPassword,
                                  value,
                                ),
                                onFieldSubmitted: (_) => _submitLogin(),
                                hintText: l10n.loginPassword,
                                prefix: Icon(
                                  Icons.lock_outline_rounded,
                                  size: context.appComponentTokens.iconSizeMd,
                                  color: context.appTextPalette.muted,
                                ),
                                suffix: AppIconButton(
                                  key: const Key('login-password-toggle'),
                                  tooltip: _isPasswordObscured
                                      ? l10n.loginShowPassword
                                      : l10n.loginHidePassword,
                                  padding: EdgeInsets.all(
                                    context.appSpacing.xs,
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _isPasswordObscured =
                                                !_isPasswordObscured;
                                          });
                                        },
                                  icon: Icon(
                                    _isPasswordObscured
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: context.appComponentTokens.iconSizeSm,
                                  ),
                                ),
                              ),
                              if (_submitError != null) ...<Widget>[
                                SizedBox(height: spacing.md),
                                Container(
                                  key: const Key('login-error-message'),
                                  padding: EdgeInsets.all(spacing.md),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .errorContainer
                                        .withValues(alpha: 0.65),
                                    borderRadius: radius.mdBorder,
                                  ),
                                  child: Text(
                                    _submitError!,
                                    style:
                                        resolveAppTextStyle(
                                          context,
                                          size: AppTextSize.s14,
                                          weight: AppTextWeight.regular,
                                          tone: AppTextTone.secondary,
                                        ).copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                        ),
                                  ),
                                ),
                                if (_showDeployHelp) ...[
                                  SizedBox(height: spacing.sm),
                                  AppTextButton(
                                    key: const Key('login-error-deploy-guide'),
                                    label: l10n.loginDeployGuideInError,
                                    icon: Icon(
                                      Icons.open_in_new_rounded,
                                      size:
                                          context.appComponentTokens.iconSizeSm,
                                    ),
                                    size: AppTextButtonSize.small,
                                    onPressed: _isSubmitting
                                        ? null
                                        : _openDeployGuide,
                                  ),
                                ],
                              ],
                              SizedBox(height: sectionGap),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: radius.pillBorder,
                                  boxShadow: _isSubmitting
                                      ? const <BoxShadow>[]
                                      : <BoxShadow>[
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(
                                                  alpha: context
                                                      .appOverlayTokens
                                                      .surfaceShadowAlpha,
                                                ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: AppButton(
                                    key: const Key('login-submit-button'),
                                    label: _isSubmitting
                                        ? l10n.loginSubmitting
                                        : l10n.loginSubmit,
                                    variant: AppButtonVariant.primary,
                                    size: AppButtonSize.large,
                                    borderRadius: radius.pillBorder,
                                    isLoading: _isSubmitting,
                                    disabledOpacity: 1,
                                    disabledBackgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.55),
                                    disabledForegroundColor: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.92),
                                    onPressed: _isSubmitting
                                        ? null
                                        : _submitLogin,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 地址输入框左侧内嵌的协议（http/https）选择器，点击弹出下拉切换。
class _ProtocolPrefix extends StatefulWidget {
  const _ProtocolPrefix({
    required this.protocol,
    required this.enabled,
    required this.onChanged,
  });

  final String protocol;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<_ProtocolPrefix> createState() => _ProtocolPrefixState();
}

class _ProtocolPrefixState extends State<_ProtocolPrefix> {
  static const List<String> _protocols = <String>['http', 'https'];

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  @override
  void dispose() {
    _removeOverlay(notify: false);
    super.dispose();
  }

  void _toggleMenu() {
    if (!widget.enabled) {
      return;
    }
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final triggerBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (triggerBox == null) {
      return;
    }
    final triggerHeight = triggerBox.size.height;
    // 触发器较窄，菜单需要足够宽度容纳 “https://”，故取触发器宽度与最小宽度的较大值。
    final menuWidth = math.max(triggerBox.size.width, 132.0);
    final formTokens = context.appFormTokens;

    setState(() {
      _isMenuOpen = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, triggerHeight + formTokens.menuGap),
              child: Material(
                color: Colors.transparent,
                child: _ProtocolMenu(
                  width: menuWidth,
                  protocols: _protocols,
                  selected: widget.protocol,
                  onSelected: (protocol) {
                    widget.onChanged(protocol);
                    _removeOverlay();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!notify || !mounted) {
      return;
    }
    setState(() {
      _isMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          key: const Key('login-protocol-selector'),
          onTap: _toggleMenu,
          behavior: HitTestBehavior.opaque,
          child: Row(
            key: _triggerKey,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${widget.protocol}://',
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  tone: AppTextTone.secondary,
                ),
              ),
              Icon(
                _isMenuOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: context.appComponentTokens.iconSizeSm,
                color: context.appTextPalette.secondary,
              ),
              SizedBox(width: spacing.sm),
              Container(width: 1, height: 20, color: colors.borderSubtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolMenu extends StatelessWidget {
  const _ProtocolMenu({
    required this.width,
    required this.protocols,
    required this.selected,
    required this.onSelected,
  });

  final double width;
  final List<String> protocols;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overlayTokens = context.appOverlayTokens;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: context.appRadius.smBorder,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.appTextPalette.primary.withValues(
              alpha: overlayTokens.hoverAlpha,
            ),
            blurRadius: overlayTokens.surfaceShadowBlur,
            offset: Offset(0, overlayTokens.surfaceShadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: context.appRadius.smBorder,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: protocols
              .map(
                (protocol) => _ProtocolMenuItem(
                  protocol: protocol,
                  selected: protocol == selected,
                  onTap: () => onSelected(protocol),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ProtocolMenuItem extends StatefulWidget {
  const _ProtocolMenuItem({
    required this.protocol,
    required this.selected,
    required this.onTap,
  });

  final String protocol;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ProtocolMenuItem> createState() => _ProtocolMenuItemState();
}

class _ProtocolMenuItemState extends State<_ProtocolMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final formTokens = context.appFormTokens;
    final backgroundColor = widget.selected
        ? colors.surfaceMuted
        : _isHovered
        ? colors.sidebarHoverBackground
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        key: Key('login-protocol-${widget.protocol}'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: formTokens.menuItemHeight,
          padding: EdgeInsets.symmetric(
            horizontal: formTokens.fieldHorizontalPadding,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: backgroundColor),
          child: Text(
            '${widget.protocol}://',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s14,
              tone: widget.selected ? AppTextTone.accent : AppTextTone.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 登录页语言切换：首次登录即可选英文，登录失败提示也使用同一语言。
class _LoginLanguageSwitcher extends StatelessWidget {
  const _LoginLanguageSwitcher({
    required this.current,
    required this.enabled,
    required this.onSelected,
  });

  final AppLanguage current;
  final bool enabled;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.appSpacing;
    return PopupMenuButton<AppLanguage>(
      key: const Key('login-language-switcher'),
      enabled: enabled,
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<AppLanguage>>[
        PopupMenuItem<AppLanguage>(
          value: AppLanguage.zhCN,
          child: Text(l10n.settingsLanguageSimplifiedChinese),
        ),
        PopupMenuItem<AppLanguage>(
          value: AppLanguage.en,
          child: Text(l10n.settingsLanguageEnglish),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.language_rounded,
              size: context.appComponentTokens.iconSizeSm,
              color: context.appTextPalette.muted,
            ),
            SizedBox(width: spacing.xs),
            Text(
              current == AppLanguage.en
                  ? l10n.settingsLanguageEnglish
                  : l10n.settingsLanguageSimplifiedChinese,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.secondary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: context.appComponentTokens.iconSizeSm,
              color: context.appTextPalette.muted,
            ),
          ],
        ),
      ),
    );
  }
}
