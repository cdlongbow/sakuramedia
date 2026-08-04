// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_import_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// JAV 媒体导入：分页作业、详情缓存、操作与 task_run SSE 的唯一状态源。

@ProviderFor(MediaImport)
final mediaImportProvider = MediaImportProvider._();

/// JAV 媒体导入：分页作业、详情缓存、操作与 task_run SSE 的唯一状态源。
final class MediaImportProvider
    extends $AsyncNotifierProvider<MediaImport, MediaImportState> {
  /// JAV 媒体导入：分页作业、详情缓存、操作与 task_run SSE 的唯一状态源。
  MediaImportProvider._()
    : super(
        from: null,
        argument: null,
        retry: kNoAsyncNotifierRetry,
        name: r'mediaImportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaImportHash();

  @$internal
  @override
  MediaImport create() => MediaImport();
}

String _$mediaImportHash() => r'd852bd3baecf6fcfb21929dd20d7745be9796676';

/// JAV 媒体导入：分页作业、详情缓存、操作与 task_run SSE 的唯一状态源。

abstract class _$MediaImport extends $AsyncNotifier<MediaImportState> {
  FutureOr<MediaImportState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<MediaImportState>, MediaImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MediaImportState>, MediaImportState>,
              AsyncValue<MediaImportState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
