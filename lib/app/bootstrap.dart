import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/config/app_image_config.dart';
import 'package:sakuramedia/core/network/app_native_image_cache_manager.dart';
import 'package:sakuramedia/app/window_bootstrap_stub.dart'
    if (dart.library.io) 'package:sakuramedia/app/window_bootstrap_desktop.dart'
    as window_bootstrap;

Future<void> bootstrapApplication() async {
  // marionette 需要在所有其他 binding 之前初始化（binding 是单例，第一个生效）。
  // 仅 debug 模式启用，让 AI agent 通过 VM Service 截图/检查 widget 树；release 不受影响。
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  configureImageCacheBudget();
  MediaKit.ensureInitialized();
  // 把 cached_network_image 的默认 cache manager 换成走原生 TLS 栈的实现
  // （Android Cronet / iOS/macOS URLSession），让展示型图片的 TLS 指纹与
  // 系统一致；不改动任何 CachedNetworkImageProvider 调用点。
  CachedNetworkImageProvider.defaultCacheManager =
      AppNativeImageCacheManager.instance;

  if (kIsWeb) {
    // 禁用浏览器默认右键菜单，让应用内的 onSecondaryTapDown 自定义菜单生效。
    await BrowserContextMenu.disableContextMenu();
  }

  if (resolveAppPlatform() != AppPlatform.desktop) {
    return;
  }

  await window_bootstrap.bootstrapDesktopWindow();
}

@visibleForTesting
void configureImageCacheBudget() {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = AppImageConfig.imageCacheMaximumSize;
  imageCache.maximumSizeBytes = AppImageConfig.imageCacheMaximumSizeBytes;
}
