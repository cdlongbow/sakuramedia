import 'package:dio/dio.dart';

/// Web 平台占位：`native_dio_adapter`（→ `cronet_http` / `cupertino_http`）
/// 依赖 `dart:io`，Web 构建不能引入。Web 保持 dio 默认的浏览器 fetch 适配器。
void installNativePlatformAdapters({
  required Dio dio,
  required Dio refreshDio,
}) {
  // no-op
}
