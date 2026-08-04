import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/downloads/data/download_candidate_dto.dart';
import 'package:sakuramedia/features/downloads/data/download_request_dto.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';

part 'movie_detail_magnet_provider.g.dart';

enum MovieDetailMagnetSortField { sizeBytes, seeders }

enum MovieDetailMagnetSortDirection { asc, desc }

extension MovieDetailMagnetSortFieldValue on MovieDetailMagnetSortField {
  String get label => switch (this) {
    MovieDetailMagnetSortField.sizeBytes => '文件大小',
    MovieDetailMagnetSortField.seeders => '做种人数',
  };
}

extension MovieDetailMagnetSortDirectionValue
    on MovieDetailMagnetSortDirection {
  bool get isAscending => this == MovieDetailMagnetSortDirection.asc;
}

@immutable
class MovieDetailMagnetState {
  const MovieDetailMagnetState({
    this.items = const <DownloadCandidateDto>[],
    this.selectedSortField = MovieDetailMagnetSortField.sizeBytes,
    this.selectedSortDirection = MovieDetailMagnetSortDirection.desc,
    this.isLoading = false,
    this.hasSearched = false,
    this.errorMessage,
    this.submittingCandidateKey,
  });

  static const MovieDetailMagnetState initial = MovieDetailMagnetState();

  final List<DownloadCandidateDto> items;
  final MovieDetailMagnetSortField selectedSortField;
  final MovieDetailMagnetSortDirection selectedSortDirection;
  final bool isLoading;
  final bool hasSearched;
  final String? errorMessage;
  final String? submittingCandidateKey;

  List<DownloadCandidateDto> get sortedItems {
    final sorted = List<DownloadCandidateDto>.from(items);
    sorted.sort(_compare);
    return List<DownloadCandidateDto>.unmodifiable(sorted);
  }

  int _compare(DownloadCandidateDto left, DownloadCandidateDto right) {
    final primary = switch (selectedSortField) {
      MovieDetailMagnetSortField.sizeBytes => left.sizeBytes.compareTo(
        right.sizeBytes,
      ),
      MovieDetailMagnetSortField.seeders => left.seeders.compareTo(
        right.seeders,
      ),
    };
    final directional =
        selectedSortDirection.isAscending ? primary : -primary;
    if (directional != 0) return directional;
    return left.title.compareTo(right.title);
  }

  MovieDetailMagnetState copyWith({
    List<DownloadCandidateDto>? items,
    MovieDetailMagnetSortField? selectedSortField,
    MovieDetailMagnetSortDirection? selectedSortDirection,
    bool? isLoading,
    bool? hasSearched,
    Object? errorMessage = _sentinel,
    Object? submittingCandidateKey = _sentinel,
  }) {
    return MovieDetailMagnetState(
      items: items ?? this.items,
      selectedSortField: selectedSortField ?? this.selectedSortField,
      selectedSortDirection:
          selectedSortDirection ?? this.selectedSortDirection,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      submittingCandidateKey: identical(submittingCandidateKey, _sentinel)
          ? this.submittingCandidateKey
          : submittingCandidateKey as String?,
    );
  }
}

const Object _sentinel = Object();

@riverpod
class MovieDetailMagnet extends _$MovieDetailMagnet {
  bool _isDisposed = false;
  KeepAliveLink? _cacheLink;

  @override
  MovieDetailMagnetState build(String movieNumber) {
    ref.onDispose(() {
      _isDisposed = true;
      _cacheLink?.close();
      _cacheLink = null;
    });
    _cacheLink ??= ref.keepAlive();
    return MovieDetailMagnetState.initial;
  }

  KeepAliveLink? get cacheLink => _cacheLink;

  void setSortField(MovieDetailMagnetSortField field) {
    if (_isDisposed || state.selectedSortField == field) return;
    state = state.copyWith(selectedSortField: field);
  }

  void toggleSortDirection() {
    if (_isDisposed) return;
    state = state.copyWith(
      selectedSortDirection:
          state.selectedSortDirection == MovieDetailMagnetSortDirection.desc
              ? MovieDetailMagnetSortDirection.asc
              : MovieDetailMagnetSortDirection.desc,
    );
  }

  Future<void> search() async {
    if (_isDisposed || state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      hasSearched: true,
      errorMessage: null,
    );

    try {
      final items = await ref
          .read(downloadsApiProvider)
          .searchCandidates(movieNumber: movieNumber);
      if (_isDisposed) return;
      state = state.copyWith(items: items, errorMessage: null);
    } catch (_) {
      if (_isDisposed) return;
      state = state.copyWith(
        items: const <DownloadCandidateDto>[],
        errorMessage: '搜索资源失败，请稍后重试。',
      );
    } finally {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<DownloadRequestResponseDto> submitCandidate(
    DownloadCandidateDto candidate, {
    required int clientId,
  }) async {
    if (state.submittingCandidateKey != null) {
      throw StateError('download request already running');
    }
    state = state.copyWith(submittingCandidateKey: candidate.submitKey);
    try {
      return await ref
          .read(downloadsApiProvider)
          .createDownloadRequest(
            movieNumber: movieNumber,
            clientId: clientId,
            candidate: candidate,
          );
    } finally {
      if (!_isDisposed) {
        state = state.copyWith(submittingCandidateKey: null);
      }
    }
  }
}
