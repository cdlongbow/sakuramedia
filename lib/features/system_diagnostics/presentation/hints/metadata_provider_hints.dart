import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/features/system_diagnostics/presentation/hints/diagnostic_hints.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';

/// JavDB 元数据源诊断 hint。
///
/// - 外部站点请求统一跟随容器环境变量 `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` 分流
///   （httpx `trust_env` 默认开启），由部署方自行决定哪些域名走代理、哪些直连。
///
/// key 与后端 [MetadataProviderErrorType] 的三个取值一一对应，外加一个前端侧的
/// `probe-request-failed`（调 `/metadata-providers/{p}/test` 本身就失败了）。

DiagnosticHint _probeRequestFailedHint(AppLocalizations l10n) => DiagnosticHint(
  cause: l10n.diagnosticHintProbeRequestFailedCause,
  fixHint: l10n.diagnosticHintBackendCheckRetryFix,
);

/// JavDB 侧一律不给 fixTarget：真正的修法在路由器/透明代理一侧（见 wiki
/// 「常见问题 · 代理配置」），SakuraMedia 里没有对应开关。
Map<String, DiagnosticHint> javdbHints(AppLocalizations l10n) =>
    <String, DiagnosticHint>{
      MetadataProviderErrorType.notFound: DiagnosticHint(
        cause: l10n.diagnosticHintJavdbNotFoundCause,
        fixHint: l10n.diagnosticHintJavdbNotFoundFix,
      ),
      MetadataProviderErrorType.requestError: DiagnosticHint(
        cause: l10n.diagnosticHintJavdbUnreachableCause,
        fixHint: l10n.diagnosticHintJavdbUnreachableFix,
      ),
      MetadataProviderErrorType.unexpected: DiagnosticHint(
        cause: l10n.diagnosticHintJavdbUnexpectedCause,
        fixHint: l10n.diagnosticHintJavdbUnexpectedFix,
      ),
      'probe-request-failed': _probeRequestFailedHint(l10n),
    };

/// 按后端 `error.type` 分派 hint key。
///
/// [error] 为 null（healthy=false 但没带 error，理论上不会出现）或 type 不认识时，
/// 归到 `unexpected_error`。
String resolveMetadataProviderHintKey(
  StatusMetadataProviderTestErrorDto? error,
) {
  return switch (error?.type) {
    MetadataProviderErrorType.notFound => MetadataProviderErrorType.notFound,
    MetadataProviderErrorType.requestError =>
      MetadataProviderErrorType.requestError,
    _ => MetadataProviderErrorType.unexpected,
  };
}
