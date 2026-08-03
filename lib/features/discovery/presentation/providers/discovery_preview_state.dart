import 'package:flutter/foundation.dart';

/// 发现首屏预览区块的 State(今日推荐 / 推荐时刻两条腿共用形状)。
///
/// 保留迁移前 `DiscoveryController` 的字段语义:
/// - [isLoading]:load / refresh 进行中都置真(refresh 期间 items 保留,
///   moments 区块的 UI 会在 loading 时显示骨架——这是现状行为,勿改)。
/// - [errorMessage]:load 失败必置;refresh 失败且已有旧数据时**静默保留**
///   (不置错、不清列表)。
@immutable
class DiscoveryPreviewState<T> {
  const DiscoveryPreviewState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<T> items;
  final int total;
  final bool isLoading;
  final String? errorMessage;
}
