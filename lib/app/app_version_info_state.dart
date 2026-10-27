import 'package:flutter/foundation.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';

@immutable
class AppVersionInfoState {
  const AppVersionInfoState({
    this.frontendVersion = '',
    this.backendVersion = '',
    this.isLoading = false,
    this.hasLoaded = false,
  });

  static const AppVersionInfoState initial = AppVersionInfoState();

  final String frontendVersion;
  final String backendVersion;
  final bool isLoading;
  final bool hasLoaded;

  String get frontendVersionLabel => _versionOrPlaceholder(frontendVersion);
  String get backendVersionLabel => _versionOrPlaceholder(backendVersion);

  /// 版本信息 tooltip；按当前语言渲染。
  String tooltipLabelFor(AppLocalizations l10n) =>
      l10n.appVersionTooltip(frontendVersionLabel, backendVersionLabel);

  /// 旧的中文 tooltip，保留给尚未迁移的调用点。
  String get tooltipLabel =>
      '客户端 $frontendVersionLabel · 服务端 $backendVersionLabel';

  AppVersionInfoState copyWith({
    String? frontendVersion,
    String? backendVersion,
    bool? isLoading,
    bool? hasLoaded,
  }) {
    return AppVersionInfoState(
      frontendVersion: frontendVersion ?? this.frontendVersion,
      backendVersion: backendVersion ?? this.backendVersion,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

String _versionOrPlaceholder(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '--' : trimmed;
}
