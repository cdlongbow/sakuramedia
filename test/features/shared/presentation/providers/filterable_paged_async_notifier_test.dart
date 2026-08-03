import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';

typedef _Fetcher =
    Future<PaginatedResponseDto<int>> Function(int page, int pageSize, int filter);

final _fetcherProvider = Provider<_Fetcher>((ref) {
  throw UnimplementedError('override _fetcherProvider in test');
});

class _State {
  const _State({
    required this.paged,
    this.filter = 0,
    this.selected = const <int>{},
    this.isReloading = false,
  });

  final PagedListState<int> paged;
  final int filter;
  final Set<int> selected;
  final bool isReloading;

  _State copyWith({
    PagedListState<int>? paged,
    int? filter,
    Set<int>? selected,
    bool? isReloading,
  }) => _State(
    paged: paged ?? this.paged,
    filter: filter ?? this.filter,
    selected: selected ?? this.selected,
    isReloading: isReloading ?? this.isReloading,
  );
}

class _SpinnerNotifier extends AsyncNotifier<_State>
    with
        PagedAsyncNotifierMixin<_State, int>,
        FilterablePagedAsyncNotifierMixin<_State, int, int> {
  @override
  int get pageSize => 3;

  @override
  String get initialLoadErrorText => 'initial-err';

  @override
  String get loadMoreErrorText => 'load-more-err';

  @override
  PagedListState<int> pagedOf(_State state) => state.paged;

  @override
  _State applyPaged(_State state, PagedListState<int> paged) =>
      state.copyWith(paged: paged);

  @override
  int get initialFilter => 0;

  @override
  _State applyFilterToState(_State state, int filter) =>
      state.copyWith(filter: filter, selected: const <int>{});

  @override
  Future<PaginatedResponseDto<int>> fetchPage(int page, int pageSize) =>
      ref.read(_fetcherProvider)(page, pageSize, activeFilter);

  @override
  Future<_State> build() async {
    attachDisposeGuard();
    final paged = await loadInitialPage();
    return _State(paged: paged, filter: activeFilter);
  }
}

final _spinnerProvider = AsyncNotifierProvider<_SpinnerNotifier, _State>(
  _SpinnerNotifier.new,
  retry: (_, __) => null,
);

class _PreserveNotifier extends AsyncNotifier<_State>
    with
        PagedAsyncNotifierMixin<_State, int>,
        FilterablePagedAsyncNotifierMixin<_State, int, int> {
  @override
  int get pageSize => 3;

  @override
  String get initialLoadErrorText => 'initial-err';

  @override
  String get loadMoreErrorText => 'load-more-err';

  @override
  PagedListState<int> pagedOf(_State state) => state.paged;

  @override
  _State applyPaged(_State state, PagedListState<int> paged) =>
      state.copyWith(paged: paged);

  @override
  int get initialFilter => 0;

  @override
  _State applyFilterToState(_State state, int filter) =>
      state.copyWith(filter: filter);

  @override
  FilterReloadStrategy get filterReloadStrategy =>
      FilterReloadStrategy.preserveList;

  @override
  _State copyWithReloading(_State state, bool reloading) =>
      state.copyWith(isReloading: reloading);

  @override
  Future<PaginatedResponseDto<int>> fetchPage(int page, int pageSize) =>
      ref.read(_fetcherProvider)(page, pageSize, activeFilter);

  @override
  Future<_State> build() async {
    attachDisposeGuard();
    final paged = await loadInitialPage();
    return _State(paged: paged, filter: activeFilter);
  }
}

final _preserveProvider = AsyncNotifierProvider<_PreserveNotifier, _State>(
  _PreserveNotifier.new,
  retry: (_, __) => null,
);

PaginatedResponseDto<int> _page({
  required int page,
  required List<int> items,
  required int total,
}) => PaginatedResponseDto<int>(
  items: items,
  page: page,
  pageSize: 3,
  total: total,
  syncedAt: null,
);

void main() {
  late List<int> filtersUsed;
  late ProviderContainer container;

  setUp(() {
    filtersUsed = <int>[];
    container = ProviderContainer(
      overrides: [
        _fetcherProvider.overrideWithValue(
          (page, pageSize, filter) async {
            filtersUsed.add(filter);
            return _page(
              page: page,
              items: List<int>.generate(3, (i) => filter * 100 + i),
              total: 3,
            );
          },
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('spinner 策略：切筛选走 AsyncLoading、拉第一页、写回 filter', () async {
    await container.read(_spinnerProvider.future);
    expect(container.read(_spinnerProvider).value!.filter, 0);

    final pending = Future<_State>(() => container.read(_spinnerProvider.future));
    final fut = container.read(_spinnerProvider.notifier).applyFilterState(1);
    // reload 同步切成 AsyncLoading。
    expect(container.read(_spinnerProvider), isA<AsyncLoading<_State>>());
    await fut;
    await pending;

    final state = container.read(_spinnerProvider);
    expect(state.value!.filter, 1);
    expect(state.value!.paged.items, [100, 101, 102]);
    expect(filtersUsed, [0, 1]);
  });

  test('spinner 策略：reload 清空多选（applyFilterToState 副作用）', () async {
    await container.read(_spinnerProvider.future);
    final notifier = container.read(_spinnerProvider.notifier);
    notifier.state = AsyncData(
      notifier.state.value!.copyWith(
        selected: const <int>{1, 2},
      ),
    );
    await notifier.applyFilterState(2);
    expect(container.read(_spinnerProvider).value!.selected, isEmpty);
    expect(container.read(_spinnerProvider).value!.filter, 2);
  });

  test('preserveList 策略：items 保留 + isReloading 先 true 后 false', () async {
    await container.read(_preserveProvider.future);
    final before = container.read(_preserveProvider).value!;

    final fut = container.read(_preserveProvider.notifier).applyFilterState(1);
    // 不切 AsyncLoading：立即进入 isReloading、旧 items 保留。
    final during = container.read(_preserveProvider);
    expect(during, isA<AsyncData<_State>>());
    expect(during.value!.isReloading, isTrue);
    expect(during.value!.filter, 1);
    expect(during.value!.paged.items, before.paged.items);

    await fut;
    final after = container.read(_preserveProvider).value!;
    expect(after.isReloading, isFalse);
    expect(after.filter, 1);
    expect(after.paged.items, [100, 101, 102]);
  });

  test('preserveList 策略：失败保留 items、isReloading 复位、抛错', () async {
    final failing = ProviderContainer(
      overrides: [
        _fetcherProvider.overrideWithValue(
          (page, pageSize, filter) async {
            if (filter == 0) {
              return _page(page: 1, items: const [1, 2, 3], total: 3);
            }
            throw Exception('boom');
          },
        ),
      ],
    );
    addTearDown(failing.dispose);
    await failing.read(_preserveProvider.future);

    await expectLater(
      failing.read(_preserveProvider.notifier).applyFilterState(1),
      throwsA(isA<Exception>()),
    );
    final after = failing.read(_preserveProvider).value!;
    expect(after.isReloading, isFalse);
    expect(after.filter, 1);
    expect(after.paged.items, [1, 2, 3]);
  });

  test('值对象等价短路：不发请求', () async {
    await container.read(_spinnerProvider.future);
    await container.read(_spinnerProvider.notifier).applyFilterState(0);
    expect(filtersUsed, [0]);
  });

  test('preserveList 未 build 完成时走 reload 兜底', () async {
    final notifier = container.read(_preserveProvider.notifier);
    await notifier.applyFilterState(3);
    final state = container.read(_preserveProvider).value!;
    expect(state.filter, 3);
    expect(state.paged.items, [300, 301, 302]);
  });

  test('preserveList 切筛选前有 in-flight loadMore：失败后 isLoadingMore 被清、可再触发', () async {
    final gate = Completer<PaginatedResponseDto<int>>();
    var loadMoreCalls = 0;
    final gated = ProviderContainer(
      overrides: [
        _fetcherProvider.overrideWithValue((page, pageSize, filter) async {
          if (filter == 0 && page == 2) {
            loadMoreCalls++;
            return gate.future;
          }
          if (filter == 1) {
            throw Exception('boom');
          }
          return _page(page: 1, items: const [1, 2, 3], total: 100);
        }),
      ],
    );
    addTearDown(gated.dispose);
    await gated.read(_preserveProvider.future);

    final notifier = gated.read(_preserveProvider.notifier);
    // 制造 in-flight loadMore：isLoadingMore = true，fetch 被 gate 卡住。
    final loadMoreFut = notifier.loadMore();
    expect(gated.read(_preserveProvider).value!.paged.isLoadingMore, isTrue);

    // 切筛选（失败路径）：不再死锁，isLoadingMore 被显式清掉。
    await expectLater(
      notifier.applyFilterState(1),
      throwsA(isA<Exception>()),
    );
    final after = gated.read(_preserveProvider).value!;
    expect(after.isReloading, isFalse);
    expect(after.paged.isLoadingMore, isFalse);
    expect(after.paged.loadMoreErrorMessage, isNull);
    expect(after.paged.items, [1, 2, 3]);

    // 被代次作废的旧 loadMore 回来后不回写：isLoadingMore 不复活、items 不变。
    gate.complete(_page(page: 2, items: const [100], total: 100));
    await loadMoreFut;
    final afterDiscard = gated.read(_preserveProvider).value!;
    expect(afterDiscard.paged.isLoadingMore, isFalse);
    expect(afterDiscard.paged.items, [1, 2, 3]);
    expect(loadMoreCalls, 1);

    // 可再次触发 loadMore（不死锁）——filter=1 的 fetchPage 抛错 → loadMoreError
    await notifier.loadMore();
    final afterRetry = gated.read(_preserveProvider).value!;
    expect(afterRetry.paged.isLoadingMore, isFalse);
    expect(afterRetry.paged.loadMoreErrorMessage, 'load-more-err');
  });
}
