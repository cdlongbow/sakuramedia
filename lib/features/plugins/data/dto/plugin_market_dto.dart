import 'package:sakuramedia/core/json/json_parse.dart';

/// 插件市场索引（`index.json`）整体结构。
class PluginMarketCatalogDto {
  const PluginMarketCatalogDto({
    required this.schemaVersion,
    this.updatedAt,
    required this.plugins,
  });

  final int schemaVersion;
  final DateTime? updatedAt;
  final List<PluginMarketItemDto> plugins;

  factory PluginMarketCatalogDto.fromJson(Map<String, dynamic> json) {
    final rawPlugins = json['plugins'];
    return PluginMarketCatalogDto(
      schemaVersion: asInt(json['schema_version']),
      updatedAt: asDateTime(json['updated_at']),
      plugins: <PluginMarketItemDto>[
        if (rawPlugins is List)
          for (final item in rawPlugins)
            if (asMapOrNull(item) case final map?)
              PluginMarketItemDto.fromJson(map),
      ],
    );
  }
}

/// 插件市场索引中的单个插件条目。
class PluginMarketItemDto {
  const PluginMarketItemDto({
    required this.pluginId,
    required this.displayName,
    required this.description,
    required this.author,
    required this.repo,
    this.homepage,
    this.iconUrl,
    this.categories = const <String>[],
    this.official = false,
    this.latest,
  });

  final String pluginId;
  final String displayName;
  final String description;
  final String author;
  final String repo;
  final String? homepage;
  final String? iconUrl;
  final List<String> categories;
  final bool official;
  final PluginMarketReleaseDto? latest;

  /// 项目主页地址：`homepage` 合法时优先，否则回退 GitHub 仓库地址。
  ///
  /// 两者都不可用时返回 `null`，调用方据此隐藏入口。
  String? get homepageUrl {
    final home = homepage;
    if (home != null && _isHttpUrl(home)) {
      return home;
    }
    if (repo.isEmpty) {
      return null;
    }
    return 'https://github.com/$repo';
  }

  factory PluginMarketItemDto.fromJson(Map<String, dynamic> json) {
    return PluginMarketItemDto(
      pluginId: asStringOrNull(json['plugin_id'], trim: true) ?? '',
      displayName: asStringOrNull(json['display_name'], trim: true) ?? '',
      description: asStringOrNull(json['description'], trim: true) ?? '',
      author: asStringOrNull(json['author'], trim: true) ?? '',
      repo: asStringOrNull(json['repo'], trim: true) ?? '',
      homepage: asStringOrNull(json['homepage'], trim: true),
      iconUrl: asStringOrNull(json['icon'], trim: true),
      categories: asStringList(json['categories'], trim: true),
      official: json['official'] == true,
      latest: switch (asMapOrNull(json['latest'])) {
        final map? => PluginMarketReleaseDto.fromJson(map),
        null => null,
      },
    );
  }
}

/// 市场索引中插件的最新 Release 信息（由索引仓库自动同步）。
class PluginMarketReleaseDto {
  const PluginMarketReleaseDto({
    required this.version,
    required this.hostApiVersion,
    required this.downloadUrl,
    this.sha256,
    this.publishedAt,
  });

  final String version;
  final int hostApiVersion;
  final String downloadUrl;
  final String? sha256;
  final DateTime? publishedAt;

  factory PluginMarketReleaseDto.fromJson(Map<String, dynamic> json) {
    return PluginMarketReleaseDto(
      version: asStringOrNull(json['version'], trim: true) ?? '',
      hostApiVersion: asInt(json['host_api_version']),
      downloadUrl: asStringOrNull(json['download_url'], trim: true) ?? '',
      sha256: asStringOrNull(json['sha256'], trim: true),
      publishedAt: asDateTime(json['published_at']),
    );
  }
}

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}
