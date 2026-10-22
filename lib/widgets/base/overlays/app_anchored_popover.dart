import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:sakuramedia/theme.dart';

/// 可被外部（例如浮层内的操作）关闭的浮层句柄。
class AppPopoverController {
  VoidCallback? _close;

  void close() => _close?.call();

  void _attach(VoidCallback close) => _close = close;

  void _detach(VoidCallback close) {
    if (_close == close) {
      _close = null;
    }
  }
}

/// 浮层相对触发器的展开方向与水平对齐。
///
/// `start` 是面板左边缘对齐触发器左边缘、向右延伸；`end` 是面板右边缘对齐
/// 触发器右边缘、向左延伸。面板比触发器宽时整体平移，避免超出 overlay。
enum AppPopoverPlacement { belowStart, belowEnd, aboveStart, aboveEnd }

extension on AppPopoverPlacement {
  bool get isAbove =>
      this == AppPopoverPlacement.aboveStart ||
      this == AppPopoverPlacement.aboveEnd;

  bool get isEnd =>
      this == AppPopoverPlacement.belowEnd ||
      this == AppPopoverPlacement.aboveEnd;
}

/// 浮层可用空间。面板样式、滚动和 footer 仍由调用方决定。
///
/// [maxHeight] 只在向下展开时按触发器下方剩余空间计算；向上展开时为 null，
/// 由面板内容自行约束高度。
class AppPopoverLayout {
  const AppPopoverLayout({required this.width, required this.maxHeight});

  final double width;
  final double? maxHeight;
}

typedef AppPopoverTriggerBuilder =
    Widget Function(BuildContext context, bool isOpen, VoidCallback toggle);

typedef AppPopoverPanelBuilder =
    Widget Function(
      BuildContext overlayContext,
      AppPopoverLayout layout,
      VoidCallback close,
    );

/// 面板宽度；参数依次为 overlay 上下文、触发器宽度、overlay 宽度。
typedef AppPopoverPanelWidthBuilder =
    double Function(
      BuildContext overlayContext,
      double triggerWidth,
      double overlayWidth,
    );

/// 通用「触发器 + 锚定浮层」骨架。
///
/// 负责 LayerLink、OverlayEntry、全屏遮罩、触发器测量、位置与可用高度计算、
/// 外部点击关闭，以及可选的入场动画和 Esc 关闭。面板自身的背景、圆角、滚动
/// 和 footer 留给调用方，避免把不同业务的面板样式塞进共享层。
///
/// 面板内容不要放 Tooltip：Flutter 3.47 的 Tooltip 走 OverlayPortal，在
/// CompositedTransformFollower 内布局时拿不到父级 paint transform。
class AppAnchoredPopover extends StatefulWidget {
  const AppAnchoredPopover({
    super.key,
    required this.triggerBuilder,
    required this.panelBuilder,
    required this.panelWidthBuilder,
    this.placement = AppPopoverPlacement.belowStart,
    this.gap = 8,
    this.enabled = true,
    this.animate = false,
    this.focusOnOpen = false,
    this.onOpened,
    this.controller,
    this.initialTriggerSize = const Size(160, 36),
  });

  final AppPopoverTriggerBuilder triggerBuilder;
  final AppPopoverPanelBuilder panelBuilder;
  final AppPopoverPanelWidthBuilder panelWidthBuilder;

  final AppPopoverPlacement placement;
  final double gap;
  final bool enabled;
  final bool animate;
  final bool focusOnOpen;
  final VoidCallback? onOpened;
  final AppPopoverController? controller;
  final Size initialTriggerSize;

  @override
  State<AppAnchoredPopover> createState() => _AppAnchoredPopoverState();
}

class _AppAnchoredPopoverState extends State<AppAnchoredPopover> {
  static const Duration _animationDuration = Duration(milliseconds: 140);

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'app-anchored-popover');
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _overlayRebuildScheduled = false;
  late Size _triggerSize = widget.initialTriggerSize;
  Offset _triggerOffsetInOverlay = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_closeFromController);
  }

  @override
  void didUpdateWidget(covariant AppAnchoredPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_closeFromController);
      widget.controller?._attach(_closeFromController);
    }
    _scheduleOverlayRebuild();
  }

  @override
  void dispose() {
    widget.controller?._detach(_closeFromController);
    _removeOverlay(updateState: false);
    _focusNode.dispose();
    super.dispose();
  }

  void _closeFromController() => _removeOverlay();

  void _togglePanel() {
    if (!widget.enabled) {
      return;
    }
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    widget.onOpened?.call();
    _updateTriggerMetrics();
    _isOpen = true;
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlayEntry!);
    if (widget.focusOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _focusNode.requestFocus();
        }
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleOverlayRebuild() {
    if (!_isOpen || _overlayEntry == null || _overlayRebuildScheduled) {
      return;
    }
    _overlayRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildScheduled = false;
      if (!mounted || !_isOpen) {
        return;
      }
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _updateTriggerMetrics() {
    final triggerBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (triggerBox != null) {
      _triggerSize = triggerBox.size;
    }
  }

  RenderBox? _updateTriggerMetricsForOverlay(BuildContext overlayContext) {
    final triggerBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.maybeOf(overlayContext)?.context.findRenderObject()
            as RenderBox?;

    if (triggerBox != null) {
      _triggerSize = triggerBox.size;
    }
    if (triggerBox != null && overlayBox != null) {
      _triggerOffsetInOverlay = triggerBox.localToGlobal(
        Offset.zero,
        ancestor: overlayBox,
      );
    }
    return overlayBox;
  }

  void _removeOverlay({bool updateState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayRebuildScheduled = false;
    if (updateState && _isOpen && mounted) {
      setState(() {
        _isOpen = false;
      });
      return;
    }
    _isOpen = false;
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final overlayBox = _updateTriggerMetricsForOverlay(overlayContext);
    final mediaQuery = MediaQuery.of(overlayContext);
    final overlayWidth = overlayBox?.size.width ?? mediaQuery.size.width;
    final overlayHeight = overlayBox?.size.height ?? mediaQuery.size.height;
    final isAbove = widget.placement.isAbove;

    final panelWidth = widget
        .panelWidthBuilder(overlayContext, _triggerSize.width, overlayWidth)
        .clamp(0.0, overlayWidth)
        .toDouble();
    final overflow = (panelWidth - _triggerSize.width)
        .clamp(0.0, overlayWidth)
        .toDouble();
    final horizontalOffset = widget.placement.isEnd
        // 右对齐：面板右边缘贴触发器右边缘，多出的宽度向左延伸，最多延伸
        // 到 overlay 左边界（触发器越靠右可用空间越大）。
        ? -overflow.clamp(0.0, _triggerOffsetInOverlay.dx).toDouble()
        // 左对齐：面板左边缘贴触发器左边缘；触发器太靠右导致面板会超出
        // overlay 时，再把面板整体左移到刚好贴 overlay 右边。
        : () {
            final rightSpace =
                overlayWidth - _triggerOffsetInOverlay.dx - _triggerSize.width;
            if (overflow <= rightSpace) {
              return 0.0;
            }
            return -(overflow - rightSpace).toDouble();
          }();

    double? maxHeight;
    if (!isAbove) {
      final panelTop =
          _triggerOffsetInOverlay.dy + _triggerSize.height + widget.gap;
      final bottomMargin =
          mediaQuery.padding.bottom + overlayContext.appSpacing.lg;
      final safeOverlayHeight = (overlayHeight - bottomMargin)
          .clamp(1.0, overlayHeight)
          .toDouble();
      final availablePanelHeight = safeOverlayHeight - panelTop;
      maxHeight = availablePanelHeight > 0
          ? availablePanelHeight
          : safeOverlayHeight;
    }

    final targetAnchor = isAbove ? Alignment.topLeft : Alignment.bottomLeft;
    final followerAnchor = isAbove ? Alignment.bottomLeft : Alignment.topLeft;

    Widget panel = widget.panelBuilder(
      overlayContext,
      AppPopoverLayout(width: panelWidth, maxHeight: maxHeight),
      _removeOverlay,
    );

    if (widget.animate) {
      panel = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: _animationDuration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(
                0,
                (1 - value) * context.appSpacing.xs * (isAbove ? 1 : -1),
              ),
              child: child,
            ),
          );
        },
        child: panel,
      );
    }

    if (widget.focusOnOpen) {
      panel = CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _removeOverlay,
        },
        child: Focus(focusNode: _focusNode, child: panel),
      );
    }

    return Stack(
      children: [
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
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          offset: Offset(horizontalOffset, isAbove ? -widget.gap : widget.gap),
          child: panel,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyedSubtree(
        key: _triggerKey,
        child: widget.triggerBuilder(
          context,
          _isOpen,
          widget.enabled ? _togglePanel : () {},
        ),
      ),
    );
  }
}
