import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/providers/app_shell_providers.dart';
import 'package:sakuramedia/features/image_search/presentation/image_search_file_picker.dart';
import 'package:sakuramedia/features/image_search/presentation/providers/image_search_state.dart';
import 'package:sakuramedia/features/status/presentation/providers/server_capabilities_provider.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/desktop_top_bar_config.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/l10n/app_l10n.dart';
import 'package:sakuramedia/widgets/domain/search/catalog_search_field.dart';
import 'package:sakuramedia/widgets/shell/desktop/app_sidebar_toggle_button.dart';
import 'package:sakuramedia/widgets/shell/window/app_window_drag_area.dart';
import 'package:sakuramedia/widgets/shell/window/app_windows_caption.dart';

/// 桌面壳顶栏。
///
/// 刷新按钮是**受控组件**：[onRefresh] 只是「按下的动作」（fire-and-forget），
/// [isRefreshing] 由外部（[AppDesktopShell]）持有，用来切换按钮 / spinner。
/// 这样点击按钮和 Cmd/Ctrl+R 快捷键可以共用同一份 in-flight 闸门与错误 toast。
///
/// 侧边栏收起/展开按钮由壳层固定在窗口左上角（macOS 红绿灯右侧），
/// 不在这里渲染；收起态顶栏前导留白让出按钮占位，保证标题/返回按钮
/// 排在按钮右侧。
///
/// 搜索入口固定在刷新按钮左侧，收起态是搜索图标，点击后输入框从图标
/// 左侧展开（见 [_TopBarSearchEntry]）。
class AppTopBar extends ConsumerWidget {
  const AppTopBar({
    super.key,
    required this.currentPath,
    required this.config,
    this.shellNavigatorKey,
    this.onRefresh,
    this.isRefreshing = false,
    this.overlay = false,
    this.hideActions = false,
  });

  final String currentPath;
  final DesktopTopBarConfig config;
  final GlobalKey<NavigatorState>? shellNavigatorKey;
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  /// 悬浮在沉浸内容之上：透明底 + 顶部压暗保证可读，无分隔线。
  final bool overlay;

  /// 隐藏搜索/刷新动作（详情页用不到，快捷键刷新不受影响）。
  final bool hideActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarCollapsed = ref.watch(appShellSidebarCollapsedProvider);
    // 收起态前导留白让出壳层固定的收起/展开按钮占位；与侧栏宽度
    // 用同款 180ms 线性动画，标题随之平滑滑动而不是跳变。
    final collapsedLeading =
        sidebarToggleButtonLeft(context) +
        sidebarToggleButtonSize +
        context.appSpacing.sm;

    return Container(
      key: const Key('desktop-shell-topbar'),
      decoration: overlay
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appColors.mediaOverlayStrong.withValues(alpha: 0.55),
                  context.appColors.mediaOverlayStrong.withValues(alpha: 0),
                ],
              ),
            )
          : BoxDecoration(color: context.appColors.surfaceElevated),
      child: Column(
        children: [
          SizedBox(
            key: const Key('topbar-header'),
            height: context.appComponentTokens.desktopTitleBarHeight,
            child: overlay
                ? _buildOverlayHeader(
                    context,
                    isSidebarCollapsed: isSidebarCollapsed,
                    collapsedLeading: collapsedLeading,
                  )
                : _buildStandardHeader(
                    context,
                    isSidebarCollapsed: isSidebarCollapsed,
                    collapsedLeading: collapsedLeading,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardHeader(
    BuildContext context, {
    required bool isSidebarCollapsed,
    required double collapsedLeading,
  }) {
    final spacing = context.appSpacing;
    const leftInset = AppPageInsets.desktop;
    const rightInset = AppPageInsets.desktop;
    final backButtonSlotWidth = config.isBackEnabled ? 40.0 : 0.0;
    final titleLeadingGap = config.isBackEnabled ? spacing.sm : 0.0;
    final l10n = appL10n(context);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSidebarCollapsed ? collapsedLeading : leftInset,
        ),
        if (config.isBackEnabled)
          SizedBox(
            width: backButtonSlotWidth,
            child: AppIconButton(
              key: const Key('topbar-back-button'),
              tooltip: l10n.shellBack,
              onPressed: () => _handleBack(context),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: context.appComponentTokens.iconSizeXs,
              ),
            ),
          ),
        if (titleLeadingGap > 0) SizedBox(width: titleLeadingGap),
        Expanded(
          child: AppWindowDragArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                config.title,
                key: const Key('app-topbar-title'),
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  weight: AppTextWeight.semibold,
                  tone: AppTextTone.primary,
                ),
              ),
            ),
          ),
        ),
        if (!hideActions) ...[
          _TopBarSearchEntry(currentPath: currentPath),
          SizedBox(width: spacing.xs),
          if (onRefresh != null)
            _TopBarRefreshButton(
              onPressed: onRefresh!,
              isRefreshing: isRefreshing,
            ),
        ],
        SizedBox(width: rightInset),
        if (usesAppWindowsCaption) AppWindowsCaption(),
      ],
    );
  }

  /// 沉浸页顶栏：只留一颗普通返回键（与其它顶栏同一套按钮），页面标题由
  /// 内容区自己承载。搜索/刷新在沉浸页通常隐藏；若调用方仍开启，则按普通
  /// 图标放在右侧。
  Widget _buildOverlayHeader(
    BuildContext context, {
    required bool isSidebarCollapsed,
    required double collapsedLeading,
  }) {
    final spacing = context.appSpacing;
    const leftInset = AppPageInsets.desktop;
    const rightInset = AppPageInsets.desktop;
    final l10n = appL10n(context);

    return Row(
      children: [
        SizedBox(width: isSidebarCollapsed ? collapsedLeading : leftInset),
        if (config.isBackEnabled)
          SizedBox(
            width: 40.0,
            child: AppIconButton(
              key: const Key('topbar-back-button'),
              tooltip: l10n.shellBack,
              semanticLabel: l10n.shellBack,
              onPressed: () => _handleBack(context),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: context.appComponentTokens.iconSizeXs,
                color: context.appTextPalette.onMedia,
              ),
            ),
          ),
        Expanded(child: AppWindowDragArea(child: const SizedBox.expand())),
        if (!hideActions) ...[
          _TopBarSearchEntry(currentPath: currentPath, overlay: true),
          SizedBox(width: spacing.xs),
          if (onRefresh != null)
            _TopBarRefreshButton(
              onPressed: onRefresh!,
              isRefreshing: isRefreshing,
              overlay: true,
            ),
        ],
        SizedBox(width: rightInset),
        if (usesAppWindowsCaption) AppWindowsCaption(overlay: true),
      ],
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    final shellNavigator = shellNavigatorKey?.currentState;
    if (shellNavigator != null && shellNavigator.canPop()) {
      shellNavigator.pop();
      return;
    }

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    final fallbackPath = config.fallbackPath;
    if (fallbackPath != null && fallbackPath != currentPath) {
      router.go(fallbackPath);
    }
  }
}

/// 顶栏搜索入口。
///
/// 收起态只占一个图标位；点击后输入框从图标左侧展开展示，图标原地保留
/// 作为收起开关。提交后跳转搜索页并收起；输入框聚焦时按 ESC、或路由变化
/// 时同样收起。
/// 以图搜图 / 文字搜图入口沿用旧侧边栏搜索框的行为，挂在展开输入框后缀。
class _TopBarSearchEntry extends ConsumerStatefulWidget {
  const _TopBarSearchEntry({required this.currentPath, this.overlay = false});

  final String currentPath;
  final bool overlay;

  @override
  ConsumerState<_TopBarSearchEntry> createState() => _TopBarSearchEntryState();
}

class _TopBarSearchEntryState extends ConsumerState<_TopBarSearchEntry> {
  static const double _fieldWidth = 300;
  static const Duration _animationDuration = Duration(milliseconds: 180);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'topbar-search');
  bool _expanded = true;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openAndFocus() {
    if (!mounted) {
      return;
    }
    if (!_expanded) {
      setState(() => _expanded = true);
    }
    // 输入框在本帧 setState 后才挂载，聚焦要等挂载完成。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _toggle() {
    if (_expanded) {
      _collapse();
      return;
    }
    _openAndFocus();
  }

  void _collapse() {
    _controller.clear();
    _focusNode.unfocus();
    if (mounted) {
      setState(() => _expanded = false);
    }
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    context.pushDesktopSearch(query: query, fallbackPath: widget.currentPath);
  }

  void _openTextImageSearch() {
    context.pushDesktopImageSearch(
      fallbackPath: widget.currentPath,
      initialInputKind: ImageSearchInputKind.text,
    );
  }

  Future<void> _pickAndOpenImageSearch() async {
    final l10n = appL10n(context);
    try {
      final pickedFile = await pickImageSearchFile(l10n: l10n);
      if (pickedFile == null || !mounted) {
        return;
      }
      context.pushDesktopImageSearch(
        fallbackPath: widget.currentPath,
        initialFileName: pickedFile.fileName,
        initialFileBytes: pickedFile.bytes,
        initialMimeType: pickedFile.mimeType,
      );
    } on ImageSearchFilePickerException catch (error) {
      if (mounted) {
        showToast(error.message);
      }
    } catch (_) {
      if (mounted) {
        showToast(l10n.shellImagePickFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    // 收起态不订阅能力状态，避免无关重建；展开时才决定是否显示图搜后缀。
    final imageSearchEnabled =
        _expanded && ref.watch(imageSearchEnabledProvider);
    final toggleIcon = SizedBox(
      width: _topBarActionSlotWidth,
      child: AppIconButton(
        key: const Key('topbar-search-button'),
        tooltip: _expanded ? l10n.shellCollapseSearch : l10n.baseSearchHint,
        semanticLabel: _expanded
            ? l10n.shellCollapseSearch
            : l10n.baseSearchHint,
        onPressed: _toggle,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.search_rounded,
          size: context.appComponentTokens.iconSizeSm,
          color: widget.overlay ? context.appTextPalette.onMedia : null,
        ),
      ),
    );

    return AnimatedSize(
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_expanded) ...[
            SizedBox(
              width: _fieldWidth,
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.escape): _collapse,
                },
                child: CatalogSearchField(
                  key: const Key('topbar-search-field'),
                  fieldKey: const Key('topbar-search-input'),
                  imageSearchButtonKey: const Key('topbar-search-image'),
                  textImageSearchButtonKey: const Key(
                    'topbar-search-text-image',
                  ),
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: l10n.shellSearchHintExample,
                  // 收紧到 34 高：tightSuffix 解除后缀 48px 热区下限后，
                  // 高度 = max(后缀按钮 28, 字高 14 + 2×10)。
                  tightSuffix: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.appFormTokens.fieldHorizontalPadding,
                    vertical: _compactSearchFieldVerticalPadding,
                  ),
                  // 34 高的字段上 8px 圆角偏圆，收紧到 4 更方。
                  borderRadius: context.appRadius.xsBorder,
                  showSearchButton: false,
                  showImageSearchButton: imageSearchEnabled,
                  showTextImageSearchButton: imageSearchEnabled,
                  onSubmitted: (_) => _submit(),
                  onImageSearchTap: _pickAndOpenImageSearch,
                  onTextImageSearchTap: _openTextImageSearch,
                ),
              ),
            ),
            SizedBox(width: context.appSpacing.xs),
          ],
          toggleIcon,
        ],
      ),
    );
  }
}

/// 顶栏右侧动作按钮（搜索切换 / 刷新）的占位宽度，与 AppIconButton(compact)
/// 同宽，两个图标之间只留 Row 里的固定小间距，避免中间空出一大段。
const double _topBarActionSlotWidth = appCompactIconButtonSize;

/// 顶栏搜索框收紧后的垂直内边距：字段高 = max(28, 字高 14 + 2×10) = 34。
///
/// 没有等于 10 的间距 token（xs=4 / md=12），收到这里的命名常量，
/// 避免在 `EdgeInsets` 里出现裸数字（theme_source_guard 禁令）。
const double _compactSearchFieldVerticalPadding = 10;

class _TopBarRefreshButton extends StatelessWidget {
  const _TopBarRefreshButton({
    required this.onPressed,
    required this.isRefreshing,
    this.overlay = false,
  });

  final VoidCallback onPressed;
  final bool isRefreshing;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final tokens = context.appComponentTokens;
    final iconSize = tokens.iconSizeSm;

    if (isRefreshing) {
      return SizedBox(
        key: const Key('topbar-refresh-button-loading'),
        width: _topBarActionSlotWidth,
        child: Center(
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator.adaptive(
              backgroundColor: switch (Theme.of(context).platform) {
                TargetPlatform.iOS || TargetPlatform.macOS =>
                  overlay
                      ? context.appTextPalette.onMedia
                      : context.appTextPalette.muted,
                _ => null,
              },
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color?>(
                overlay
                    ? context.appTextPalette.onMedia
                    : context.appTextPalette.muted,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: _topBarActionSlotWidth,
      child: AppIconButton(
        key: const Key('topbar-refresh-button'),
        tooltip: l10n.commonRefresh,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.refresh_rounded,
          size: iconSize,
          color: overlay ? context.appTextPalette.onMedia : null,
        ),
      ),
    );
  }
}
