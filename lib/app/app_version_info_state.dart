import 'package:flutter/foundation.dart';

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
