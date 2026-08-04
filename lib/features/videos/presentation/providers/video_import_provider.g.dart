// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_import_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// PornBox 视频导入：与 JAV 导入保持逐项平行的 Riverpod 状态源。

@ProviderFor(VideoImport)
final videoImportProvider = VideoImportProvider._();

/// PornBox 视频导入：与 JAV 导入保持逐项平行的 Riverpod 状态源。
final class VideoImportProvider
    extends $AsyncNotifierProvider<VideoImport, VideoImportState> {
  /// PornBox 视频导入：与 JAV 导入保持逐项平行的 Riverpod 状态源。
  VideoImportProvider._()
    : super(
        from: null,
        argument: null,
        retry: kNoAsyncNotifierRetry,
        name: r'videoImportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoImportHash();

  @$internal
  @override
  VideoImport create() => VideoImport();
}

String _$videoImportHash() => r'e5e7bf8419f797f515275e7daf14668a4474c43f';

/// PornBox 视频导入：与 JAV 导入保持逐项平行的 Riverpod 状态源。

abstract class _$VideoImport extends $AsyncNotifier<VideoImportState> {
  FutureOr<VideoImportState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<VideoImportState>, VideoImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<VideoImportState>, VideoImportState>,
              AsyncValue<VideoImportState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
