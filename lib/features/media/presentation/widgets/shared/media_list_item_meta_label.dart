import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/core/format/media_timecode.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';

/// 媒体行卡 / 组卡共用的单行元数据文案：`媒体库 · 大小 · 时长 · 分辨率`。
///
/// 空项跳过；库信息缺失时按「媒体库已删除 / 媒体库 N」兜底。
String buildMediaListItemMetaLabel(
  MediaListItemDto item, {
  MediaLibraryDto? library,
}) {
  final libraryName = library?.name.trim();
  final libraryLabel = libraryName != null && libraryName.isNotEmpty
      ? library!.name
      : item.libraryName?.trim().isNotEmpty == true
      ? item.libraryName!
      : item.libraryId == null
      ? '媒体库已删除'
      : '媒体库 ${item.libraryId}';
  final resolution = item.resolution?.trim();
  return <String>[
    libraryLabel,
    formatFileSize(item.fileSizeBytes),
    if (item.durationSeconds > 0)
      formatMediaDurationLabel(item.durationSeconds),
    if (resolution != null && resolution.isNotEmpty) resolution,
  ].join(' · ');
}
