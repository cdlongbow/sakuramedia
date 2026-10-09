import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';

/// 通用横向滚动 rail：固定高度的横向列表 + 指针悬停时显示左右翻页箭头。
///
/// - 箭头只在「指针悬停」且该方向真的还能滚动时出现；触摸端没有 hover，
///   天然不出现，无需平台判断。
/// - 点击箭头按视口宽度的 85% 动画滚动，保留上一屏的部分卡片作上下文。
/// - 卡片由调用方通过 [itemBuilder] 提供，通常自行包 `SizedBox` 固定宽度；
///   横向鼠标拖拽由全局 ScrollConfiguration 的 dragDevices 提供。
class AppHoverScrollRail extends StatefulWidget {
  const AppHoverScrollRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollViewKey,
  });

  /// rail 高度；卡片高度由调用方按自身宽高比算好。
  final double height;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Key? scrollViewKey;

  @override
  State<AppHoverScrollRail> createState() => _AppHoverScrollRailState();
}

class _AppHoverScrollRailState extends State<AppHoverScrollRail> {
  /// 单次翻页比例：略小于一屏，滚完仍能看到上一屏的一张卡。
  static const double _pageScrollFactor = 0.85;
  static const Duration _pageScrollDuration = Duration(milliseconds: 220);

  final ScrollController _controller = ScrollController();
  bool _hovered = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncScrollBounds);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollBounds());
  }

  @override
  void didUpdateWidget(AppHoverScrollRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollBounds());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncScrollBounds() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final canScrollLeft = position.pixels > position.minScrollExtent + 0.5;
    final canScrollRight = position.pixels < position.maxScrollExtent - 0.5;
    if (canScrollLeft == _canScrollLeft && canScrollRight == _canScrollRight) {
      return;
    }
    setState(() {
      _canScrollLeft = canScrollLeft;
      _canScrollRight = canScrollRight;
    });
  }

  void _scrollByPage(double direction) {
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final target =
        (position.pixels +
                position.viewportDimension * _pageScrollFactor * direction)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: _pageScrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing.sm;
    return MouseRegion(
      // onEnter 时补一次边界同步：窗口 resize 改变可滚动性后，
      // ScrollController 监听不会触发，箭头需在下次悬停时纠正。
      onEnter: (_) {
        setState(() => _hovered = true);
        _syncScrollBounds();
      },
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            ListView.separated(
              key: widget.scrollViewKey,
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemCount,
              separatorBuilder: (context, index) => SizedBox(width: spacing),
              itemBuilder: widget.itemBuilder,
            ),
            if (_hovered && _canScrollLeft)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _RailArrowButton(
                    key: const Key('hover-rail-arrow-left'),
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: '向左滚动',
                    onTap: () => _scrollByPage(-1),
                  ),
                ),
              ),
            if (_hovered && _canScrollRight)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _RailArrowButton(
                    key: const Key('hover-rail-arrow-right'),
                    icon: Icons.chevron_right_rounded,
                    semanticLabel: '向右滚动',
                    onTap: () => _scrollByPage(1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 圆底翻页箭头：复用媒体浮层按钮的「深底 + 描边 + 白图标」范式。
class _RailArrowButton extends StatelessWidget {
  const _RailArrowButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tokens = context.appComponentTokens;
    final size = tokens.buttonHeightSm;
    return AppInteractiveSurface(
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.mediaOverlayStrong,
          shape: BoxShape.circle,
          border: Border.all(color: colors.mediaOverlayBorder),
        ),
        child: Icon(
          icon,
          size: tokens.iconSizeMd,
          color: context.appTextPalette.onMedia,
        ),
      ),
    );
  }
}
