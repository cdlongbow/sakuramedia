// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_version_movies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MultiVersionMovies)
final multiVersionMoviesProvider = MultiVersionMoviesProvider._();

final class MultiVersionMoviesProvider
    extends
        $AsyncNotifierProvider<
          MultiVersionMovies,
          PagedListState<MultiVersionMovieDto>
        > {
  MultiVersionMoviesProvider._()
    : super(
        from: null,
        argument: null,
        retry: kNoAsyncNotifierRetry,
        name: r'multiVersionMoviesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiVersionMoviesHash();

  @$internal
  @override
  MultiVersionMovies create() => MultiVersionMovies();
}

String _$multiVersionMoviesHash() =>
    r'a9b16395f42eb18db5b40d6a2b19a4488bafb848';

abstract class _$MultiVersionMovies
    extends $AsyncNotifier<PagedListState<MultiVersionMovieDto>> {
  FutureOr<PagedListState<MultiVersionMovieDto>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PagedListState<MultiVersionMovieDto>>,
              PagedListState<MultiVersionMovieDto>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PagedListState<MultiVersionMovieDto>>,
                PagedListState<MultiVersionMovieDto>
              >,
              AsyncValue<PagedListState<MultiVersionMovieDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
