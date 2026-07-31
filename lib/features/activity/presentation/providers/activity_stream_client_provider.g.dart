// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_stream_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 通知中心专用 SSE 流客户端（原生装配）。

@ProviderFor(activityEventStreamClient)
final activityEventStreamClientProvider = ActivityEventStreamClientProvider._();

/// 通知中心专用 SSE 流客户端（原生装配）。

final class ActivityEventStreamClientProvider
    extends
        $FunctionalProvider<
          ActivityEventStreamClient,
          ActivityEventStreamClient,
          ActivityEventStreamClient
        >
    with $Provider<ActivityEventStreamClient> {
  /// 通知中心专用 SSE 流客户端（原生装配）。
  ActivityEventStreamClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityEventStreamClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityEventStreamClientHash();

  @$internal
  @override
  $ProviderElement<ActivityEventStreamClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActivityEventStreamClient create(Ref ref) {
    return activityEventStreamClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityEventStreamClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityEventStreamClient>(value),
    );
  }
}

String _$activityEventStreamClientHash() =>
    r'13873f95963a6854e54e335e45b12fad7887d698';
