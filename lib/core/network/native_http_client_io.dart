import 'dart:io' show Platform;

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;

/// 构造一个走平台原生栈的 `http.Client`，用于 [flutter_cache_manager] 场景
/// （`CachedNetworkImageProvider` 的图片下载）——目的是让**图片下载**的
/// TLS 指纹也跟系统一致，避免 dart:io BoringSSL 被 DPI 命中。
///
/// 平台分派（与 `native_dio_adapter_installer_io.dart` 保持对称）：
/// - **Android** → `CronetClient.defaultCronetEngine()`。gradle 已把
///   `play-services-cronet` 替换为 `org.chromium.net:cronet-embedded`
///   （见 `android/build.gradle.kts`），因此不依赖 Google Play Services。
///   Cronet 引擎在首次请求时懒初始化；同一进程内的 dio Adapter 与本 client
///   会各自持有自己的引擎，代价可接受（引擎本身几 MB，不重复占用 native so）。
/// - **iOS / macOS** → `CupertinoClient.defaultSessionConfiguration()`
///   （URLSession 默认配置）。
/// - **Windows / Linux** → 返回 null，让上层回退到 `http.Client()` 默认
///   （即 `IOClient` + `dart:io HttpClient`），本项目按需求不改桌面端。
///
/// 返回 null 时调用方必须回退到 `http.Client()`。
http.Client? createNativePlatformHttpClient() {
  if (Platform.isAndroid) {
    return CronetClient.defaultCronetEngine();
  }
  if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoClient.defaultSessionConfiguration();
  }
  return null;
}
