import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';

/// 错误提示的统一入口：服务端 message 已按请求语言本地化，前端只兜底传输失败。
String localizedApiErrorMessage(
  AppLocalizations l10n,
  Object error, {
  required String fallback,
}) {
  if (error is ApiException) {
    if (error.isTransportFailure) {
      final baseUrl = error.baseUrl?.trim();
      return switch (error.transportFailureKind) {
        ApiTransportFailureKind.timeout
            when baseUrl != null && baseUrl.isNotEmpty =>
          l10n.errorTimeoutWithHost(baseUrl),
        ApiTransportFailureKind.timeout => l10n.errorTimeout,
        _ when baseUrl != null && baseUrl.isNotEmpty =>
          l10n.errorNetworkFailureWithHost(baseUrl),
        _ => l10n.errorNetworkFailure,
      };
    }
    return error.error?.message ?? error.message;
  }
  return fallback;
}
