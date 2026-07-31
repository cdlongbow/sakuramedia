import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/configuration/data/api/indexer_settings_api.dart';

part 'indexer_settings_api_provider.g.dart';

/// configuration 域 IndexerSettingsApi 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<IndexerSettingsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
IndexerSettingsApi indexerSettingsApi(Ref ref) {
  throw UnimplementedError(
    'Override indexerSettingsApiProvider at the app root',
  );
}
