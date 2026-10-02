/// Provider-owned opaque source reference selected from the browse response.
class MediaImportSource {
  const MediaImportSource({required this.sourceRef});

  final Map<String, dynamic> sourceRef;

  Map<String, dynamic> toJson() => <String, dynamic>{'source_ref': sourceRef};
}

/// How the storage provider should handle the source after a successful import.
enum SourceDisposition { keep, deleteAfterCommit, inPlace }

extension SourceDispositionX on SourceDisposition {
  String get wireValue => switch (this) {
    SourceDisposition.keep => 'keep',
    SourceDisposition.deleteAfterCommit => 'delete_after_commit',
    SourceDisposition.inPlace => 'in_place',
  };

  String get label => switch (this) {
    SourceDisposition.keep => '保留源文件',
    SourceDisposition.deleteAfterCommit => '导入成功后删除源文件',
    SourceDisposition.inPlace => '原地导入（不复制文件）',
  };

  String get description => switch (this) {
    SourceDisposition.keep => '将源文件复制到媒体库中，导入后不会删除源文件',
    SourceDisposition.deleteAfterCommit => '将源文件复制到媒体库中，导入成功后删除源文件',
    SourceDisposition.inPlace => '不复制文件，媒体直接引用源文件当前位置',
  };
}
