import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

/// 把 dio 的传输适配器换成平台原生实现，目的是让 TLS ClientHello
/// 与平台系统栈一致（Cronet ≈ Chrome / URLSession ≈ Safari），
/// 摆脱 dart:io BoringSSL 的小众指纹被 DPI 命中。
///
/// 平台分派（Web 走 stub 文件，本文件不覆盖）：
/// - **Android** → `cronet_http`（Cronet）。gradle 里已把 `play-services-cronet`
///   替换为 `org.chromium.net:cronet-embedded`（`android/build.gradle.kts`），
///   所以不依赖 Google Play Services，国内 ROM 也能跑；代价是 APK **+ ~15MB**。
///   fallback：Cronet 全提供者被停用时（AOSP 模拟器等），降级到 `IOHttpClientAdapter`
///   —— 此时**指纹回到 dart:io 的原状**，仅保证功能可用。
/// - **iOS / macOS** → `cupertino_http`（URLSession）。默认 `URLSessionConfiguration`
///   即可，无需额外配置。
/// - **Windows / Linux** → `native_dio_adapter` 内部 fallback 到 dart:io 默认适配器
///   （即 dio 现状），本项目按需求不改桌面端。
///
/// 主/refresh 两个 dio 都换，保持行为对称（token 刷新走的 `_refreshDio` 独立
/// 无拦截器，但仍需相同的传输栈）。
void installNativePlatformAdapters({
  required Dio dio,
  required Dio refreshDio,
}) {
  if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
    // Windows / Linux：保持 dio 默认。
    return;
  }
  try {
    dio.httpClientAdapter = NativeAdapter(
      createFallbackAdapter: (_, __) => IOHttpClientAdapter(),
    );
    refreshDio.httpClientAdapter = NativeAdapter(
      createFallbackAdapter: (_, __) => IOHttpClientAdapter(),
    );
  } catch (_) {
    // `flutter test` 等纯 VM 环境不一定携带 URLSession/Cronet 的 native asset。
    // 适配器不可用时保持 Dio 默认行为，不能让网络 client 本身无法构造。
    dio.httpClientAdapter = IOHttpClientAdapter();
    refreshDio.httpClientAdapter = IOHttpClientAdapter();
  }
}
