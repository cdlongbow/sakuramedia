import 'package:flutter/foundation.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/routes/app_back_destination.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_route_spec.dart';
import 'package:sakuramedia/routes/desktop_image_search_route_state.dart';
import 'package:sakuramedia/routes/desktop_navigation_route_state.dart';
import 'package:sakuramedia/routes/desktop_search_route_state.dart';

@immutable
class DesktopTopBarConfig {
  const DesktopTopBarConfig({
    required this.title,
    required this.fallbackPath,
    required this.isBackEnabled,
  });

  final String title;
  final String? fallbackPath;
  final bool isBackEnabled;
}

/// 顶栏标题按当前语言解析；导航目的地的标题直接取导航项标签。
DesktopTopBarConfig resolveDesktopTopBarConfig({
  required String currentPath,
  required List<AppNavGroup> navGroups,
  required AppLocalizations l10n,
  Object? routeExtra,
}) {
  if (currentPath == desktopOverviewPath) {
    return DesktopTopBarConfig(
      title: l10n.routeOverviewTitle,
      fallbackPath: null,
      isBackEnabled: false,
    );
  }

  if (currentPath == desktopSystemDiagnosticsPath) {
    return DesktopTopBarConfig(
      title: l10n.systemDiagnosticsComponentTitle,
      fallbackPath: desktopOverviewPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopDiscoverMoviesPath) {
    return DesktopTopBarConfig(
      title: l10n.routeRecommendedMoviesTitle,
      fallbackPath: desktopDiscoverPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopDiscoverMomentsPath) {
    return DesktopTopBarConfig(
      title: l10n.routeRecommendedMomentsTitle,
      fallbackPath: desktopDiscoverPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopLatestMoviesPath) {
    return DesktopTopBarConfig(
      title: l10n.routeLatestAddedTitle,
      fallbackPath: desktopOverviewPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopRecentlySubscribedMoviesPath) {
    return DesktopTopBarConfig(
      title: l10n.routeRecentlySubscribedTitle,
      fallbackPath: desktopOverviewPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopRecentViewsPath) {
    return DesktopTopBarConfig(
      title: l10n.routeRecentViewsTitle,
      fallbackPath: desktopOverviewPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopFavoritesPath) {
    return DesktopTopBarConfig(
      title: l10n.routeFavoritesTitle,
      fallbackPath: desktopOverviewPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopRecentlyPlayedPath) {
    return DesktopTopBarConfig(
      title: l10n.routeRecentlyPlayedTitle,
      fallbackPath: desktopOverviewPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopHotActressReleasesPath) {
    return DesktopTopBarConfig(
      title: l10n.routePopularNewReleasesTitle,
      fallbackPath: desktopDiscoverPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopFollowPath) {
    return DesktopTopBarConfig(
      title: l10n.routeNewActorReleasesTitle,
      fallbackPath: desktopDiscoverPath,
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith(desktopMovieSeriesPathPrefix)) {
    return DesktopTopBarConfig(
      title: l10n.routeSeriesMoviesTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('/desktop/library/movies/')) {
    return DesktopTopBarConfig(
      title: l10n.routeMovieDetailsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('/desktop/library/actors/')) {
    return DesktopTopBarConfig(
      title: l10n.routeActorDetailsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('$desktopTagsPath/')) {
    return DesktopTopBarConfig(
      title: l10n.routeTagsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('/desktop/library/playlists/')) {
    return DesktopTopBarConfig(
      title: l10n.routePlaylistDetailsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('$desktopVideosPath/')) {
    if (currentPath.endsWith('/thumbnails')) {
      return DesktopTopBarConfig(
        title: l10n.routeThumbnailsTitle,
        fallbackPath:
            _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
            AppBackDestination.defaultLocationForPath(currentPath),
        isBackEnabled: true,
      );
    }
    return DesktopTopBarConfig(
      title: l10n.routeVideoDetailsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopVideoCollectionsPath) {
    return DesktopTopBarConfig(
      title: l10n.routeVideoCollectionsTitle,
      fallbackPath: desktopVideosPath,
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('$desktopVideoCollectionsPath/')) {
    return DesktopTopBarConfig(
      title: l10n.routeCollectionDetailsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          desktopVideoCollectionsPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopClipCollectionsPath) {
    return DesktopTopBarConfig(
      title: l10n.routeClipCollectionsTitle,
      fallbackPath: desktopClipsPath,
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('$desktopClipCollectionsPath/')) {
    return DesktopTopBarConfig(
      title: l10n.routeCollectionDetailsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          desktopClipCollectionsPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopMomentCollectionsPath) {
    return DesktopTopBarConfig(
      title: l10n.routeMomentCollectionsTitle,
      fallbackPath: desktopMomentsPath,
      isBackEnabled: true,
    );
  }

  if (currentPath.startsWith('$desktopMomentCollectionsPath/')) {
    return DesktopTopBarConfig(
      title: l10n.routeCollectionDetailsTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          desktopMomentCollectionsPath,
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopImageSearchPath) {
    return DesktopTopBarConfig(
      title: l10n.routeImageSearchTitle,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  if (currentPath == desktopSearchPath ||
      currentPath.startsWith('$desktopSearchPath/')) {
    final title = currentPath == desktopSearchPath
        ? l10n.routeSearchTitle
        : _decodeSearchTitleSegment(
            currentPath.substring(desktopSearchPath.length + 1),
          );
    return DesktopTopBarConfig(
      title: title,
      fallbackPath:
          _fallbackPathFromExtra(routeExtra, currentPath: currentPath) ??
          AppBackDestination.defaultLocationForPath(currentPath),
      isBackEnabled: true,
    );
  }

  final navItems = navGroups
      .expand((group) => group.items)
      .toList(growable: false);
  final currentItem = navItems.firstWhere(
    (item) => item.path == currentPath,
    orElse: () => navItems.first,
  );
  return DesktopTopBarConfig(
    title: currentItem.label,
    fallbackPath: null,
    isBackEnabled: false,
  );
}

String _decodeSearchTitleSegment(String value) {
  try {
    return Uri.decodeComponent(value);
  } on ArgumentError {
    return value;
  }
}

String? _fallbackPathFromExtra(
  Object? routeExtra, {
  required String currentPath,
}) {
  final fallbackPath = switch (routeExtra) {
    DesktopNavigationRouteState(:final fallbackPath) => fallbackPath,
    DesktopSearchRouteState(:final fallbackPath) => fallbackPath,
    DesktopImageSearchRouteState(:final fallbackPath) => fallbackPath,
    String value when _allowsLegacyStringExtra(currentPath, value) => value,
    _ => null,
  };
  if (fallbackPath != null && fallbackPath.startsWith('/desktop/')) {
    return fallbackPath;
  }
  return null;
}

bool _allowsLegacyStringExtra(String currentPath, String fallbackPath) {
  if (!fallbackPath.startsWith('/desktop/')) {
    return false;
  }
  if (currentPath == desktopImageSearchPath ||
      currentPath == desktopSearchPath ||
      currentPath.startsWith('$desktopSearchPath/')) {
    return true;
  }
  if (currentPath.startsWith('/desktop/library/movies/')) {
    return fallbackPath.startsWith(desktopMoviesPath);
  }
  if (currentPath.startsWith('/desktop/library/actors/') ||
      currentPath.startsWith('/desktop/library/playlists/')) {
    return fallbackPath.startsWith('/desktop/library/');
  }
  return false;
}

AppShellLayout resolveDesktopShellLayout({
  required String currentPath,
  required List<AppRouteSpec> routeSpecs,
}) {
  if (currentPath.startsWith(desktopMovieSeriesPathPrefix)) {
    return AppShellLayout.standard;
  }

  if (currentPath.startsWith('/desktop/library/movies/')) {
    // 播放器（…/player）保持原布局，只有影片详情页走沉浸。
    final suffix = currentPath.substring('/desktop/library/movies/'.length);
    if (suffix.contains('/')) {
      return AppShellLayout.standard;
    }
    return AppShellLayout.immersive;
  }

  if (currentPath.startsWith('/desktop/library/actors/')) {
    return AppShellLayout.standard;
  }

  if (currentPath.startsWith('$desktopTagsPath/')) {
    return AppShellLayout.standard;
  }

  if (currentPath.startsWith('/desktop/library/playlists/')) {
    return AppShellLayout.standard;
  }

  if (currentPath.startsWith('$desktopVideosPath/') ||
      currentPath.startsWith('$desktopVideoCollectionsPath/')) {
    return AppShellLayout.standard;
  }

  if (currentPath == desktopClipCollectionsPath ||
      currentPath.startsWith('$desktopClipCollectionsPath/')) {
    return AppShellLayout.standard;
  }

  final currentSpec = routeSpecs.firstWhere(
    (spec) => spec.path == currentPath,
    orElse: () => routeSpecs.first,
  );
  return currentSpec.layout;
}
