import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import 'package:sakuramedia/core/network/native_http_client_stub.dart'
    if (dart.library.io)
        'package:sakuramedia/core/network/native_http_client_io.dart';

/// 走平台原生 HTTP 栈的图片缓存管理器，喂给 `cached_network_image`
/// 用（本项目通过替换 `CachedNetworkImageProvider.defaultCacheManager`
/// 让所有调用点自动切过来，见 `bootstrap.dart`）。
///
/// 与默认 `DefaultCacheManager` 的差别只有 `fileService` 的 http.Client：
/// - 默认走 `package:http` 的 `IOClient`（= `dart:io HttpClient` = Dart 内嵌
///   BoringSSL，TLS 指纹小众易被 DPI 命中）。
/// - 本管理器用 Android Cronet / iOS/macOS URLSession，指纹与系统一致。
///
/// 缓存目录另起新的 `cacheKey`（`appNativeImage`）——不复用旧的
/// `libCachedImageData`，因为老缓存条目可能是被 DPI 干扰过的错误响应或部分
/// 内容；新起一份从零开始更干净，代价是升级后首次显示需重新下载。
class AppNativeImageCacheManager extends CacheManager
    with ImageCacheManager {
  AppNativeImageCacheManager._()
      : super(
          Config(
            key,
            fileService: HttpFileService(
              httpClient: createNativePlatformHttpClient() ?? http.Client(),
            ),
          ),
        );

  static const String key = 'appNativeImage';

  static final AppNativeImageCacheManager instance =
      AppNativeImageCacheManager._();
}
