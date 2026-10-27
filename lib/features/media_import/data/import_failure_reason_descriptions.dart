import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/l10n/app_localizations_zh.dart';

/// 失败条目原因（`failed_files[].reason`）到当前语言短文案的映射。
///
/// 只覆盖导入流程当前会写入的原因；插件错误码等未知取值回退原值。
///
/// 未传 [l10n] 时回退简体中文，供尚未迁移的调用点使用。
String describeImportFailureReason(String code, {AppLocalizations? l10n}) {
  final l = l10n ?? AppLocalizationsZh();
  return switch (code) {
    'movie_number_not_found' => l.mediaImportFailureMovieNumberNotFound,
    'metadata_fetch_failed' => l.mediaImportFailureMetadataFetchFailed,
    'image_download_failed' => l.mediaImportFailureImageDownloadFailed,
    'metadata_upsert_failed' => l.mediaImportFailureMetadataUpsertFailed,
    'media_import_failed' => l.mediaImportFailureMediaImportFailed,
    'file_too_small' => l.mediaImportFailureFileTooSmall,
    'unsupported_format' => l.mediaImportFailureUnsupportedFormat,
    'already_indexed_path' => l.mediaImportFailureAlreadyIndexedPath,
    _ => code.isEmpty ? l.mediaImportFailureUnknownReason : code,
  };
}
