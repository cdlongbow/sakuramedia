import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';

/// 标签匹配模式（任一/全部）的当前语言标签。
///
/// [TagMatchMode.label] 只有中文，标签域的文案一律走 ARB。
String tagMatchModeLabel(TagMatchMode mode, AppLocalizations l10n) {
  return switch (mode) {
    TagMatchMode.or => l10n.tagMatchModeOr,
    TagMatchMode.and => l10n.tagMatchModeAnd,
  };
}
