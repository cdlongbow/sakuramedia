import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart'
    as media;
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';
import 'package:sakuramedia/features/shared/presentation/providers/session_scoped_invalidation.dart';

part 'media_libraries_provider.g.dart';

/// 跨桌面 configuration tab 与移动设置页共享的媒体库列表。
@Riverpod(keepAlive: true, retry: kNoAsyncNotifierRetry)
class MediaLibraries extends _$MediaLibraries
    with AsyncNotifierDisposeGuardMixin<List<MediaLibraryDto>> {
  @override
  Future<List<MediaLibraryDto>> build() async {
    invalidateOnSignOut(ref);
    attachDisposeGuard();
    return ref.read(mediaLibrariesApiProvider).getLibraries();
  }

  Future<void> reload() async {
    state = const AsyncLoading<List<MediaLibraryDto>>();
    final next = await AsyncValue.guard(
      () => ref.read(mediaLibrariesApiProvider).getLibraries(),
    );
    if (!isDisposed) state = next;
  }

  /// 下拉刷新保留已呈现的列表；失败由调用方显示轻提示。
  Future<String?> refresh() async {
    final current = state.value;
    if (current == null) {
      await reload();
      return state.hasError
          ? apiErrorMessage(state.error!, fallback: '媒体库加载失败，请稍后重试。')
          : null;
    }
    try {
      final next = await ref.read(mediaLibrariesApiProvider).getLibraries();
      if (!isDisposed) state = AsyncData(next);
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: '媒体库加载失败，请稍后重试。');
    }
  }

  Future<MediaLibraryDto> create(CreateMediaLibraryPayload payload) async {
    final created = await ref
        .read(mediaLibrariesApiProvider)
        .createLibrary(payload);
    upsert(created);
    return created;
  }

  Future<MediaLibraryDto> updateLibrary({
    required int libraryId,
    required UpdateMediaLibraryPayload payload,
  }) async {
    final updated = await ref
        .read(mediaLibrariesApiProvider)
        .updateLibrary(libraryId: libraryId, payload: payload);
    upsert(updated);
    return updated;
  }

  Future<void> delete(int libraryId) async {
    await ref.read(mediaLibrariesApiProvider).deleteLibrary(libraryId);
    if (isDisposed) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current
          .where((library) => library.id != libraryId)
          .toList(growable: false),
    );
    _invalidateMediaDomainCopy();
  }

  /// media 域另有一份 keepAlive 的媒体库快照（`MediaLibrariesState`，多带一层
  /// 派生的 storageDescriptors / cloud115Libraries，媒体管理与维护页在用）。
  /// 两份是各自拉取的，本域改完库不通知它的话，媒体管理页的库筛选会一直显示
  /// 旧列表直到重启——CRUD 后让它失效，下次进页面自然重拉。
  ///
  /// 用 invalidate 而不是补丁：那份状态的派生字段在构造函数里算，就地打补丁
  /// 还得重算一遍，不如让它重拉。
  void _invalidateMediaDomainCopy() {
    ref.invalidate(media.mediaLibrariesProvider);
  }

  /// Cloud115 流程在 View 中完成后，调用方用其返回 DTO 回写共享列表。
  void upsert(MediaLibraryDto library) {
    if (isDisposed) return;
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((item) => item.id == library.id);
    final next = List<MediaLibraryDto>.from(current);
    if (index < 0) {
      next.insert(0, library);
    } else {
      next[index] = library;
    }
    state = AsyncData(next);
    _invalidateMediaDomainCopy();
  }
}
