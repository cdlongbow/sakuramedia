import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/discovery/data/discovery_api.dart';

part 'discovery_api_provider.g.dart';

/// discovery 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<DiscoveryApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
DiscoveryApi discoveryApi(Ref ref) {
  throw UnimplementedError('Override discoveryApiProvider at the app root');
}
