import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_menu_widgets.dart';

typedef PlayerSplitPanelBuilder = Widget Function(BuildContext context);

/// 播放器左右分栏的共享壳：桌面端固定分栏；移动端（[collapsible]）默认收起
/// 右面板，通过右缘毛玻璃把手展开/收起，展开后仍可用分隔条拖拽调节宽度。
///
/// 收起/展开由右侧 [Area.flex] 驱动（0 = 收起）：收起时右侧子树卸载，展开时挂载；
/// 左侧子树始终挂在同一个 [MultiSplitView] 的同一位置，保证调用方的播放器 State
/// 不因开关面板重建。把手在收起态吸右缘、展开态停靠分隔条中点，点击切换、横拖跟手。
class CollapsiblePlayerSplitView extends StatefulWidget {
  const CollapsiblePlayerSplitView({
    super.key,
    required this.controller,
    required this.leftBuilder,
    required this.rightBuilder,
    this.dividerHandleBuffer = 0,
    this.collapsible = false,
    this.panelAvailable = true,
    this.handleKey,
    this.defaultPanelFlex = 0.28,
  });

  final MultiSplitViewController controller;
  final PlayerSplitPanelBuilder leftBuilder;
  final PlayerSplitPanelBuilder rightBuilder;
  final double dividerHandleBuffer;

  /// 移动端传 true：进入时右侧面板收起，显示右缘把手。
  final bool collapsible;

  /// 右侧面板是否有内容可展示；无内容时不显示把手。
  final bool panelAvailable;
  final Key? handleKey;

  /// 首次展开时使用的面板 flex，也是记忆宽度的兜底值。
  final double defaultPanelFlex;

  @override
  State<CollapsiblePlayerSplitView> createState() =>
      _CollapsiblePlayerSplitViewState();
}

class _CollapsiblePlayerSplitViewState extends State<CollapsiblePlayerSplitView>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 220);
  static const double _collapsedFlexThreshold = 0.0001;
  static const double _rememberedFlexFloor = 0.04;
  static const double _dragCollapseFlexThreshold = 0.02;
  static const double _maxPanelWidthFactor = 0.92;
  static const double _handleWidth = 28;
  static const double _handleHeight = 64;

  late final AnimationController _animationController;
  Animation<double>? _flexTween;
  double _rememberedPanelFlex = 0.28;

  MultiSplitViewController get _controller => widget.controller;
  double get _panelFlex => _controller.areas[1].flex ?? 0;
  bool get _panelExpanded => _panelFlex > _collapsedFlexThreshold;

  @override
  void initState() {
    super.initState();
    _rememberedPanelFlex = widget.defaultPanelFlex;
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..addListener(_applyFlexAnimationTick);
    _controller.addListener(_handleControllerChanged);
    if (widget.collapsible) {
      if (_panelExpanded) {
        _rememberedPanelFlex = _panelFlex;
      }
      _controller.areas[1].flex = 0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final flex = _panelFlex;
    if (!_animationController.isAnimating && flex >= _rememberedFlexFloor) {
      _rememberedPanelFlex = flex;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _applyFlexAnimationTick() {
    final tween = _flexTween;
    if (tween == null) {
      return;
    }
    _controller.areas[1].flex = tween.value;
  }

  void _animatePanelFlexTo(double target) {
    final from = _panelFlex;
    if ((from - target).abs() < _collapsedFlexThreshold) {
      _flexTween = null;
      _controller.areas[1].flex = target;
      return;
    }
    _flexTween = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward(from: 0);
  }

  void _togglePanel() {
    if (_panelExpanded) {
      if (_panelFlex >= _rememberedFlexFloor) {
        _rememberedPanelFlex = _panelFlex;
      }
      _animatePanelFlexTo(0);
      return;
    }
    _animatePanelFlexTo(_rememberedPanelFlex);
  }

  void _handleHandleDragStart() {
    _animationController.stop();
    _flexTween = null;
  }

  void _handleHandleDragUpdate(DragUpdateDetails details, double layoutWidth) {
    final available = math.max(layoutWidth - context.appSpacing.xs, 1.0);
    final currentWidth = _panelPixelWidth(_panelFlex, available);
    final targetWidth = (currentWidth - details.delta.dx).clamp(
      0.0,
      available * _maxPanelWidthFactor,
    );
    _controller.areas[1].flex = _flexForPanelWidth(targetWidth, available);
  }

  void _handleHandleDragEnd() {
    if (_panelFlex < _dragCollapseFlexThreshold) {
      _animatePanelFlexTo(0);
    }
  }

  double _panelPixelWidth(double flex, double available) {
    final otherFlex = _controller.areas[0].flex ?? 1;
    final totalFlex = otherFlex + flex;
    if (totalFlex <= 0) {
      return 0;
    }
    return available * flex / totalFlex;
  }

  double _flexForPanelWidth(double width, double available) {
    if (width <= 0) {
      return 0;
    }
    final otherFlex = _controller.areas[0].flex ?? 1;
    return otherFlex * width / (available - width);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final expanded = _panelExpanded;
    final showHandle = widget.collapsible && widget.panelAvailable;
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: spacing.xs,
        dividerHandleBuffer: widget.dividerHandleBuffer,
        dividerPainter: DividerPainters.grooved1(
          color: context.appColors.borderSubtle,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              MultiSplitView(
                controller: widget.controller,
                axis: Axis.horizontal,
                builder: (context, area) => area.index == 0
                    ? widget.leftBuilder(context)
                    : expanded
                    ? widget.rightBuilder(context)
                    : const SizedBox.shrink(),
              ),
              if (showHandle) _buildHandle(context, constraints, expanded),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHandle(
    BuildContext context,
    BoxConstraints constraints,
    bool expanded,
  ) {
    final dividerThickness = context.appSpacing.xs;
    final available = math.max(constraints.maxWidth - dividerThickness, 0.0);
    final panelWidth = _panelPixelWidth(_panelFlex, available);
    final dividerCenterX = available - panelWidth + dividerThickness / 2;
    final handleRight = math.max(
      constraints.maxWidth - dividerCenterX - _handleWidth / 2,
      0.0,
    );
    final handleTop = math.max(
      (constraints.maxHeight - _handleHeight) / 2,
      0.0,
    );
    return Positioned(
      right: handleRight,
      top: handleTop,
      child: Semantics(
        button: true,
        label: expanded ? '收起缩略图面板' : '展开缩略图面板',
        child: GestureDetector(
          key: widget.handleKey,
          behavior: HitTestBehavior.opaque,
          onTap: _togglePanel,
          onHorizontalDragStart: (_) => _handleHandleDragStart(),
          onHorizontalDragUpdate: (details) =>
              _handleHandleDragUpdate(details, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _handleHandleDragEnd(),
          child: MoviePlayerGlassSurface(
            width: _handleWidth,
            height: _handleHeight,
            child: Center(
              child: Icon(
                expanded
                    ? Icons.chevron_right_rounded
                    : Icons.grid_view_rounded,
                size: context.appComponentTokens.iconSizeSm,
                color: context.appTextPalette.onMedia.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
