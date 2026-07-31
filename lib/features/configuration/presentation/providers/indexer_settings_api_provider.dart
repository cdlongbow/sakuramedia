import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/configuration/data/api/indexer_settings_api.dart';

part 'indexer_settings_api_provider.g.dart';

/// configuration 域 IndexerSettingsApi 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<IndexerSettingsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
IndexerSettingsApi indexerSettingsApi(Ref ref) {
  return IndexerSettingsApi(apiClient: ref.watch(apiClientProvider));
}
