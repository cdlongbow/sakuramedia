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
/// 新增可选 `alignment`——直接传给 `Image.alignment`，用于横图裁竖封面时需要 topCenter 等场景。
class MaskedImage extends ConsumerStatefulWidget {
  const MaskedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  static const int _decodeSizeUpperBound = 1024;

  final String url;
  final BoxFit fit;

  /// 图片在容器内的对齐方式（与 `BoxFit.cover` 组合决定裁哪一侧）。
  /// 竖封面套横框场景常传 `Alignment.topCenter` 露出海报上半部（番号+人脸）。
  final AlignmentGeometry alignment;

  final int? memCacheWidth;
  final int? memCacheHeight;

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
      return const _MaskedImagePlaceholder(icon: Icons.image_outlined);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeHint = _resolveDecodeHint(context, constraints);
        final provider = _ensureWrappedProvider(
          widget.memCacheWidth ?? decodeHint.width,
          widget.memCacheHeight ?? decodeHint.height,
        );
        if (provider == null) {
          return const _MaskedImagePlaceholder(icon: Icons.image_outlined);
        }

        Widget imageContent = Image(
          image: provider,
          fit: widget.fit,
          alignment: widget.alignment,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            // AnimatedSwitcher 默认 layoutBuilder 的 Stack 会给子级 loose
            // constraints，`Image` 便退回按自身比例布局——`cover` 实际变成
            // 「contain + 留白」。有界约束下改用 StackFit.expand，让封面真正
            // 铺满并按 `fit` 裁切。
            return LayoutBuilder(
              builder: (context, constraints) {
                final canFill =
                    constraints.hasBoundedWidth &&
                    constraints.hasBoundedHeight;
                return AnimatedSwitcher(
                  duration: _revealFadeDuration,
                  switchInCurve: Curves.easeOut,
                  layoutBuilder: canFill
                      ? _fillAnimatedSwitcherLayout
                      : AnimatedSwitcher.defaultLayoutBuilder,
                  // 两个 child 必须有不同 key：AnimatedSwitcher 只在 key 变化时保留
                  // 旧 child 做淡出，否则占位会瞬间消失。
                  child: frame == null
                      ? const _MaskedImagePlaceholder(
                          key: ValueKey<String>('placeholder'),
                          icon: Icons.image_outlined,
                        )
                      : KeyedSubtree(
                          key: const ValueKey<String>('image'),
                          child: child,
                        ),
                );
              },
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const _MaskedImagePlaceholder(
              icon: Icons.broken_image_outlined,
            );
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

/// 首帧到达前显示占位；`contain` 图片周围不再有底色。
class _MaskedImagePlaceholder extends StatelessWidget {
  const _MaskedImagePlaceholder({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final componentTokens = context.appComponentTokens;

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surfaceMuted),
      child: Center(
        child: Icon(
          icon,
          size: componentTokens.iconSize3xl,
          color: context.appTextPalette.muted,
        ),
      ),
    );
  }
}
