// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_task_center_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ResourceTaskCenter)
final resourceTaskCenterProvider = ResourceTaskCenterProvider._();

final class ResourceTaskCenterProvider
    extends
        $AsyncNotifierProvider<ResourceTaskCenter, ResourceTaskCenterState> {
  ResourceTaskCenterProvider._()
    : super(
        from: null,
        argument: null,
        retry: kNoAsyncNotifierRetry,
        name: r'resourceTaskCenterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourceTaskCenterHash();

  @$internal
  @override
  ResourceTaskCenter create() => ResourceTaskCenter();
}

String _$resourceTaskCenterHash() =>
    r'8e1aad102f7aa6e1494333f94676fe683b64ff3b';

abstract class _$ResourceTaskCenter
    extends $AsyncNotifier<ResourceTaskCenterState> {
  FutureOr<ResourceTaskCenterState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ResourceTaskCenterState>,
              ResourceTaskCenterState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ResourceTaskCenterState>,
                ResourceTaskCenterState
              >,
              AsyncValue<ResourceTaskCenterState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
