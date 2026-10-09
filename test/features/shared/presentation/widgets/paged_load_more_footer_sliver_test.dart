import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_load_more_footer_sliver.dart';

class _PagedNotifier extends Notifier<PagedListState<int>> {
  @override
  PagedListState<int> build() => const PagedListState<int>();

  void write(PagedListState<int> next) => state = next;
}

final _pagedProvider = NotifierProvider<_PagedNotifier, PagedListState<int>>(
  _PagedNotifier.new,
);

void main() {
  test('withoutLoadMoreStatus 只清翻页状态，已经中立时返回原对象', () {
    const neutral = PagedListState<int>(items: <int>[1, 2]);
    expect(identical(withoutLoadMoreStatus(neutral), neutral), isTrue);

    final cleared = withoutLoadMoreStatus(
      neutral.copyWith(isLoadingMore: true, loadMoreErrorMessage: 'boom'),
    );
    expect(cleared.isLoadingMore, isFalse);
    expect(cleared.loadMoreErrorMessage, isNull);
    expect(cleared.items, <int>[1, 2]);
  });

  test('列表本体订阅中立化后的值：翻页状态翻转不通知', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(_pagedProvider.notifier);
    var notifications = 0;
    container.listen(_pagedProvider.select(withoutLoadMoreStatus), (_, _) {
      notifications++;
    });

    notifier.write(const PagedListState<int>(items: <int>[1, 2]));
    notifier.write(
      const PagedListState<int>(items: <int>[1, 2], isLoadingMore: true),
    );
    notifier.write(
      const PagedListState<int>(
        items: <int>[1, 2],
        loadMoreErrorMessage: 'boom',
      ),
    );
    notifier.write(const PagedListState<int>(items: <int>[1, 2, 3]));

    // 两次翻页状态翻转不通知，条目变化各通知一次。
    expect(notifications, 2);
  });
}
