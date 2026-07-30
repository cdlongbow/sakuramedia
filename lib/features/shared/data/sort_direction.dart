/// 通用升/降序枚举。跨 feature 共用（movies / rankings / playlists / …）。
///
/// 各域按需 re-export 或直接引用，避免下游反向依赖具体 feature 的 presentation 层。
enum SortDirection { asc, desc }

extension SortDirectionX on SortDirection {
  String get apiValue => switch (this) {
    SortDirection.asc => 'asc',
    SortDirection.desc => 'desc',
  };

  String get label => switch (this) {
    SortDirection.asc => '升序',
    SortDirection.desc => '降序',
  };
}
