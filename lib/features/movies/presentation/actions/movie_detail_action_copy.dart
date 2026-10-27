import 'package:sakuramedia/l10n/app_localizations.dart';

/// 「刷新元数据」二次确认的文案，按当前语言取值。
class MovieDetailRefreshConfirmationCopy {
  const MovieDetailRefreshConfirmationCopy._();

  static String title(AppLocalizations l10n) => l10n.movieActionRefreshMetadata;

  static String hint(AppLocalizations l10n) =>
      l10n.movieActionRefreshMetadataHint;

  static String cancelLabel(AppLocalizations l10n) => l10n.commonCancel;

  static String confirmLabel(AppLocalizations l10n) =>
      l10n.movieActionRefreshMetadataConfirm;

  static String descriptionFor(
    AppLocalizations l10n, {
    required bool isActorsManuallyManaged,
  }) {
    return isActorsManuallyManaged
        ? l10n.movieActionRefreshMetadataDescriptionManualActors
        : l10n.movieActionRefreshMetadataDescription;
  }
}
