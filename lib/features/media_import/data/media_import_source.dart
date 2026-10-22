import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/l10n/app_localizations_zh.dart';

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

  /// 处置方式名（简体中文兜底）。
  ///
  /// 源文件选择器（`lib/widgets/domain/media_import`）仍按零参 getter 取值，
  /// 域内调用请改用 [labelWith] 取当前语言文案。
  String get label => labelWith(l10n: AppLocalizationsZh());

  /// 当前语言的处置方式名。
  String labelWith({required AppLocalizations l10n}) => switch (this) {
    SourceDisposition.keep => l10n.mediaImportDispositionKeep,
    SourceDisposition.deleteAfterCommit =>
      l10n.mediaImportDispositionDeleteAfterCommit,
    SourceDisposition.inPlace => l10n.mediaImportDispositionInPlace,
  };

  /// 处置方式说明（简体中文兜底）。
  ///
  /// 同 [label]：共享组件仍按零参 getter 取值，域内调用请改用 [descriptionWith]。
  String get description => descriptionWith(l10n: AppLocalizationsZh());

  /// 当前语言的处置方式说明。
  String descriptionWith({required AppLocalizations l10n}) => switch (this) {
    SourceDisposition.keep => l10n.mediaImportDispositionKeepDescription,
    SourceDisposition.deleteAfterCommit =>
      l10n.mediaImportDispositionDeleteAfterCommitDescription,
    SourceDisposition.inPlace => l10n.mediaImportDispositionInPlaceDescription,
  };
}
