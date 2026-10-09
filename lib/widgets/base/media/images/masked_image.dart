import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/config/app_image_config.dart';
import 'package:sakuramedia/core/media/app_image_provider.dart';
import 'package:sakuramedia/core/media/media_url_resolver.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/theme.dart';

/// 通用远程图入口（列表/卡片封面/头像等）。
///
/// 内部维护 ImageProvider 缓存以对抗高频 parent rebuild：
/// - 直接把 `CachedNetworkImageProvider` + 派生的 `ResizeImage` 挂在 State 上，
///   只有 `url` 或 decodeHint 变化时才重建；
/// - 由 `Image` widget 消费稳定的 provider，避免走过去 `CachedNetworkImage → OctoImage`
///   路径下每次 build 因 `ResizeImage` 无 `==` 覆盖被视为"新图"导致 Image element
///   被 `ValueKey(image)` 强制替换、fade 动画 250ms 重放的闪烁问题。
/// - 首帧到达后由 frameBuilder 里的 `AnimatedSwitcher` 完成「占位 → 图片」切换，
///   占位随切换结束自动移除；provider identity 稳定，高频 rebuild 不会重放动画，
///   内存缓存命中（`wasSynchronouslyLoaded`）时直接显示。
/// - URL 切换时暂存上一次解码成功的 provider：新图加载中继续展示旧图，
///   首帧到达后再做一次新旧淡入，避免闪回占位（`Image.gaplessPlayback` 单独
///   加无效：切换时 `_frameNumber` 会被重置，frameBuilder 仍走占位分支）。
/// 新增可选 `alignment`——直接传给 `Image.alignment`，用于横图裁竖封面时需要 topCenter 等场景。
/// 新增可选 `placeholderColor` / `animateReveal`——有连续底色的场景（如影片详情）
/// 让占位与底色同色、背景图关闭淡入，把「骨架 → 占位 → 图片」两次跳变收成一次。
class MaskedImage extends ConsumerStatefulWidget {
  const MaskedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholderColor,
    this.animateReveal = true,
  });

  static const int _decodeSizeUpperBound = 1024;

  final String url;
  final BoxFit fit;

  /// 图片在容器内的对齐方式（与 `BoxFit.cover` 组合决定裁哪一侧）。
  /// 竖封面套横框场景常传 `Alignment.topCenter` 露出海报上半部（番号+人脸）。
  final AlignmentGeometry alignment;

  final int? memCacheWidth;
  final int? memCacheHeight;

  /// 首帧到达前占位的纯色：不传时用 `surfaceMuted`。
  /// 有连续底色的场景传入底色（如详情 Hero 传 veil 色、模糊背景传 base 色），
  /// 避免「骨架 → 占位 → 图片」在占位处再跳一次颜色。
  final Color? placeholderColor;

  /// 首帧到达后是否做「占位 → 图片」淡入。罩了重 veil 的背景图传 false：
  /// 解码完成后直接显示，避免与前景图两次先后闪烁。
  final bool animateReveal;

  @override
  ConsumerState<MaskedImage> createState() => _MaskedImageState();
}

class _MaskedImageState extends ConsumerState<MaskedImage> {
  /// baseUrl 拼过后的完整 URL；null 表示解析不出可用地址（会走 placeholder）。
  String? _resolvedUrl;

  /// 未包 ResizeImage 的裸 network provider。同一 URL 复用同一实例，
  /// 保持 identity 稳定 → didUpdateWidget 里 `oldWidget.image != widget.image` 走"未变"分支。
  ImageProvider<Object>? _baseProvider;

  /// 应用了 memCacheWidth/Height 的 ResizeImage 包装；若两者都为空则退化为 base。
  ImageProvider<Object>? _wrappedProvider;
  int? _lastDecodeWidth;
  int? _lastDecodeHeight;

  /// 最近一次成功解出首帧的派生 provider。URL 切换、新图加载中
  /// （frame == null）时用它继续展示旧图；新图首帧到达后再淡入。
  /// 首进（无旧帧）时为 null，走占位分支，与过去行为一致。
  ImageProvider<Object>? _lastCompletedProvider;

  void _rebuildBaseProviderIfNeeded(String baseUrl) {
    final resolvedUrl = resolveMediaUrl(rawUrl: widget.url, baseUrl: baseUrl);
    if (resolvedUrl == _resolvedUrl) {
      return;
    }
    _resolvedUrl = resolvedUrl;
    _baseProvider =
        resolvedUrl == null ? null : buildRemoteImageProvider(resolvedUrl);
    // decodeHint 关联的派生 provider 需要跟着重算。
    _wrappedProvider = null;
    _lastDecodeWidth = null;
    _lastDecodeHeight = null;
  }

  /// 按当前布局的 decodeHint 派生（或复用）ResizeImage 包装。
  /// 关键：同一 (baseProvider, w, h) 组合始终返回**同一 ImageProvider 实例**，
  /// 让 Image widget 的 didUpdateWidget 判定"图片未变"，跳过 element 重建。
  ImageProvider<Object>? _ensureWrappedProvider(int? width, int? height) {
    if (_baseProvider == null) {
      return null;
    }
    if (_wrappedProvider != null &&
        _lastDecodeWidth == width &&
        _lastDecodeHeight == height) {
      return _wrappedProvider;
    }
    _lastDecodeWidth = width;
    _lastDecodeHeight = height;
    if (width == null && height == null) {
      _wrappedProvider = _baseProvider;
    } else {
      _wrappedProvider = ResizeImage(
        _baseProvider!,
        width: width,
        height: height,
        allowUpscaling: false,
      );
    }
    return _wrappedProvider;
  }

  @override
  Widget build(BuildContext context) {
    // baseUrl 细粒度订阅（登录切后端时精准重建）；url/decodeHint 的缓存策略不变。
    _rebuildBaseProviderIfNeeded(ref.watch(baseUrlProvider));
    if (_baseProvider == null) {
      return _MaskedImagePlaceholder(color: widget.placeholderColor);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeHint = _resolveDecodeHint(context, constraints);
        final provider = _ensureWrappedProvider(
          widget.memCacheWidth ?? decodeHint.width,
          widget.memCacheHeight ?? decodeHint.height,
        );
        if (provider == null) {
          return _MaskedImagePlaceholder(color: widget.placeholderColor);
        }

        Widget imageContent = Image(
          image: provider,
          fit: widget.fit,
          alignment: widget.alignment,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              _lastCompletedProvider = provider;
              return child;
            }
            if (frame != null) {
              _lastCompletedProvider = provider;
              final current = KeyedSubtree(
                key: const ValueKey<String>('image'),
                child: child,
              );
              if (!widget.animateReveal) {
                return current;
              }
              return _buildReveal(child: current);
            }
            // 加载中：有旧帧时继续展示旧图（静态，不播动画），没有才走占位。
            // 新图首帧到达后，AnimatedSwitcher 会以 key 区分做一次旧图 → 新图淡入。
            final previous = _lastCompletedProvider;
            final Widget loadingChild;
            if (previous != null && previous != provider) {
              loadingChild = KeyedSubtree(
                key: const ValueKey<String>('previous-image'),
                child: Image(
                  image: previous,
                  fit: widget.fit,
                  alignment: widget.alignment,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      _MaskedImagePlaceholder(
                        color: widget.placeholderColor,
                      ),
                ),
              );
            } else {
              loadingChild = _MaskedImagePlaceholder(
                key: const ValueKey<String>('placeholder'),
                color: widget.placeholderColor,
              );
            }
            if (!widget.animateReveal) {
              return loadingChild;
            }
            return _buildReveal(child: loadingChild);
          },
          errorBuilder: (context, error, stackTrace) {
            return _MaskedImagePlaceholder(color: widget.placeholderColor);
          },
        );

        if (AppImageConfig.enableBlur && AppImageConfig.blurSigma > 0) {
          imageContent = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: AppImageConfig.blurSigma,
              sigmaY: AppImageConfig.blurSigma,
            ),
            child: imageContent,
          );
        }

        return imageContent;
      },
    );
  }

  /// 「占位 → 图片」的淡入容器。child 必须带不同 key（placeholder /
  /// previous-image / image）：AnimatedSwitcher 只在 key 变化时保留旧 child
  /// 做淡出，否则占位会瞬间消失。
  /// AnimatedSwitcher 默认 layoutBuilder 的 Stack 会给子级 loose
  /// constraints，`Image` 便退回按自身比例布局——`cover` 实际变成
  /// 「contain + 留白」。有界约束下改用 StackFit.expand，让封面真正
  /// 铺满并按 `fit` 裁切。
  Widget _buildReveal({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canFill =
            constraints.hasBoundedWidth && constraints.hasBoundedHeight;
        return AnimatedSwitcher(
          duration: _revealFadeDuration,
          switchInCurve: Curves.easeOut,
          layoutBuilder: canFill
              ? _fillAnimatedSwitcherLayout
              : AnimatedSwitcher.defaultLayoutBuilder,
          child: child,
        );
      },
    );
  }

  ({int? width, int? height}) _resolveDecodeHint(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    int? cacheWidth;
    if (constraints.hasBoundedWidth &&
        constraints.maxWidth.isFinite &&
        constraints.maxWidth > 0) {
      final rawWidth = (constraints.maxWidth * dpr).round();
      cacheWidth = rawWidth.clamp(1, MaskedImage._decodeSizeUpperBound);
    }

    int? cacheHeight;
    if (constraints.hasBoundedHeight &&
        constraints.maxHeight.isFinite &&
        constraints.maxHeight > 0) {
      final rawHeight = (constraints.maxHeight * dpr).round();
      cacheHeight = rawHeight.clamp(1, MaskedImage._decodeSizeUpperBound);
    }

    if (cacheWidth != null && cacheHeight != null) {
      return (width: cacheWidth, height: null);
    }

    return (width: cacheWidth, height: cacheHeight);
  }
}

/// 首帧到达后「占位 → 图片」的切换时长。
const Duration _revealFadeDuration = Duration(milliseconds: 240);

/// [AnimatedSwitcher] 在有界约束下的 layoutBuilder：用 `StackFit.expand` 让新旧
/// child 都铺满，避免默认 Stack 的 loose 约束把 `cover` 退化成「contain + 留白」。
Widget _fillAnimatedSwitcherLayout(
  Widget? currentChild,
  List<Widget> previousChildren,
) => Stack(
  fit: StackFit.expand,
  children: <Widget>[...previousChildren, ?currentChild],
);

/// 首帧 / 缺图 / 加载失败的统一占位：默认 muted 纯色块，不带居中图标
/// （纯图片卡的占位与骨架统一为纯块，图标会被 skeletonizer 画成实心方块）。
/// 有连续底色的场景可传 `color` 与底色对齐，避免占位处再跳一次颜色。
class _MaskedImagePlaceholder extends StatelessWidget {
  const _MaskedImagePlaceholder({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? context.appColors.surfaceMuted,
      child: const Center(),
    );
  }
}
