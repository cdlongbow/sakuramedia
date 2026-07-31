import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/media_import/data/media_import_api.dart';

part 'media_import_api_provider.g.dart';

/// media_import 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<MediaImportApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
MediaImportApi mediaImportApi(Ref ref) {
  return MediaImportApi(apiClient: ref.watch(apiClientProvider));
}
