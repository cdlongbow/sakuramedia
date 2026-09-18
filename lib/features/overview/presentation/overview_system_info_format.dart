import 'package:intl/intl.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';

/// 系统概览的纯展示格式化与状态口径（不依赖状态对象，输入即 DTO）。

final _countFormatter = NumberFormat.decimalPattern();

/// 千分位计数：`1286` → `1,286`。
String formatCount(int value) => _countFormatter.format(value);

/// 单个媒体库的容量拆分：SakuraMedia 占用 / 其他占用 / 空闲。
class StorageUsageBreakdown {
  const StorageUsageBreakdown({
    required this.sakuraBytes,
    required this.otherBytes,
    required this.freeBytes,
  });

  final int sakuraBytes;
  final int otherBytes;
  final int freeBytes;
}

/// provider 容量可用时拆分三段；总量或已用量缺失、总量无效时返回 null，
/// 由调用方退回旧展示。
///
/// `totalSizeBytes` 可能超过存储端已用量（账号级数据滞后等），按已用量收口，
/// 空闲取「总量 − 已用」，保证三段之和恒等于总量、长条不溢出。
StorageUsageBreakdown? storageUsageBreakdown(MediaLibraryUsageDto library) {
  final totalBytes = library.spaceTotalBytes;
  final usedBytes = library.spaceUsedBytes;
  if (totalBytes == null || totalBytes <= 0 || usedBytes == null) {
    return null;
  }
  final used = usedBytes.clamp(0, totalBytes).toInt();
  final sakuraBytes = library.totalSizeBytes.clamp(0, used).toInt();
  return StorageUsageBreakdown(
    sakuraBytes: sakuraBytes,
    otherBytes: used - sakuraBytes,
    freeBytes: totalBytes - used,
  );
}

/// 嵌入服务（JoyTag）连通性；未启用 / 探测失败各有单独文案。
String embeddingServiceHealthLabel(StatusImageSearchDto? status) {
  if (status?.enabled == false) return '未启用';
  if (status == null) {
    return '不可用';
  }
  return status.embeddingService.healthy ? '正常' : '异常';
}

AppTextTone embeddingServiceHealthTone(StatusImageSearchDto? status) {
  if (status == null || status.enabled == false) {
    return AppTextTone.muted;
  }
  return status.embeddingService.healthy
      ? AppTextTone.success
      : AppTextTone.error;
}

/// 待索引缩略图数；未启用或状态不可用时为 0（不展示积压项）。
int pendingIndexCount(StatusImageSearchDto? status) {
  if (status == null || status.enabled == false) {
    return 0;
  }
  return status.indexing.pendingThumbnails;
}

String imageSearchIndexSpaceLabel(StatusImageSearchDto? status) {
  if (status?.enabled == false) return '未启用';
  if (status == null) {
    return '不可用';
  }
  if (status.indexSpace.isRebuilding) {
    return '重建中';
  }
  return switch (status.indexSpace.state) {
    'ready' => '就绪',
    'rebuild_required' => '需重建',
    'uninitialized' => '未建立',
    'unavailable' => '不可用',
    _ => '未知',
  };
}

AppTextTone imageSearchIndexSpaceTone(StatusImageSearchDto? status) {
  if (status == null || status.enabled == false) {
    return AppTextTone.muted;
  }
  if (status.indexSpace.isRebuilding) {
    return AppTextTone.info;
  }
  return switch (status.indexSpace.state) {
    'ready' => AppTextTone.success,
    'rebuild_required' => AppTextTone.warning,
    _ => AppTextTone.muted,
  };
}
