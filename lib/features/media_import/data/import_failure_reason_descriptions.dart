/// 失败条目原因（`failed_files[].reason`）到中文短文案的映射。
///
/// 只覆盖导入流程当前会写入的原因；插件错误码等未知取值回退原值。
const Map<String, String> _kFailureReasonDescriptions = <String, String>{
  'movie_number_not_found': '未识别番号',
  'metadata_fetch_failed': '元数据获取失败',
  'image_download_failed': '封面下载失败',
  'metadata_upsert_failed': '元数据保存失败',
  'media_import_failed': '文件导入失败',
  'file_too_small': '文件过小',
  'unsupported_format': '不支持的格式',
  'already_indexed_path': '已在库中',
};

/// 返回失败原因的中文说明；未知 code 回落原值，空串落「未知原因」。
String describeImportFailureReason(String code) =>
    _kFailureReasonDescriptions[code] ?? (code.isEmpty ? '未知原因' : code);
