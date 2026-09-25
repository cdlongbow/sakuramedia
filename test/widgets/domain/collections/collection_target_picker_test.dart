import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';
import 'package:sakuramedia/widgets/domain/collections/collection_target_picker.dart';

class _Collection {
  const _Collection({
    required this.id,
    required this.name,
    required this.itemCount,
  });

  final int id;
  final String name;
  final int itemCount;
}

const _collections = <_Collection>[
  _Collection(id: 1, name: '后入', itemCount: 7),
  _Collection(id: 2, name: '指奸潮吹', itemCount: 5),
];

final _collectionsProvider = Provider<AsyncValue<List<_Collection>>>(
  (ref) => const AsyncValue.data(_collections),
);

void main() {
  Future<Future<_Collection?>> openPicker(
    WidgetTester tester, {
    required AsyncValue<List<_Collection>> collections,
    int? excludedCollectionId,
    AppAdaptiveModalVariant variant = AppAdaptiveModalVariant.dialog,
    Future<_Collection?> Function(BuildContext context, bool isDrawer)?
    onCreate,
  }) async {
    late Future<_Collection?> result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [_collectionsProvider.overrideWithValue(collections)],
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  result = showCollectionTargetPicker<_Collection>(
                    context: context,
                    variant: variant,
                    drawerKey: const Key('test-picker-bottom-sheet'),
                    optionKeyPrefix: 'test-collection-',
                    watchCollections: (ref) => ref.watch(_collectionsProvider),
                    idOf: (collection) => collection.id,
                    nameOf: (collection) => collection.name,
                    countTextOf: (collection) => '${collection.itemCount} 个切片',
                    excludedCollectionId: excludedCollectionId,
                    onCreate: onCreate ?? (context, isDrawer) async => null,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    return result;
  }

  testWidgets('点行返回所选合集', (tester) async {
    final result = await openPicker(
      tester,
      collections: const AsyncValue.data(_collections),
    );
    await tester.pumpAndSettle();

    expect(find.text('加入合集'), findsOneWidget);
    expect(find.text('7 个切片'), findsOneWidget);
    expect(find.text('新建合集并加入'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);

    await tester.tap(find.byKey(const Key('test-collection-1')));
    await tester.pumpAndSettle();

    expect((await result)?.id, 1);
    expect(find.text('加入合集'), findsNothing);
  });

  testWidgets('excludedCollectionId 对应的行不显示', (tester) async {
    await openPicker(
      tester,
      collections: const AsyncValue.data(_collections),
      excludedCollectionId: 1,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test-collection-1')), findsNothing);
    expect(find.byKey(const Key('test-collection-2')), findsOneWidget);
  });

  testWidgets('加载中显示进度指示', (tester) async {
    await openPicker(tester, collections: const AsyncValue.loading());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('暂无合集，点击下方新建'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('加载失败显示错误信息', (tester) async {
    await openPicker(
      tester,
      collections: AsyncValue.error(StateError('boom'), StackTrace.empty),
    );
    await tester.pumpAndSettle();

    expect(find.text('合集加载失败'), findsOneWidget);
  });

  testWidgets('无合集时显示空态', (tester) async {
    await openPicker(tester, collections: const AsyncValue.data([]));
    await tester.pumpAndSettle();

    expect(find.text('暂无合集，点击下方新建'), findsOneWidget);
  });

  testWidgets('新建合集后返回新建的合集并关闭弹层', (tester) async {
    var receivedIsDrawer = true;
    const created = _Collection(id: 9, name: '新合集', itemCount: 0);
    final result = await openPicker(
      tester,
      collections: const AsyncValue.data([]),
      onCreate: (context, isDrawer) async {
        receivedIsDrawer = isDrawer;
        return created;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('新建合集并加入'));
    await tester.pumpAndSettle();

    expect(receivedIsDrawer, isFalse);
    expect((await result)?.id, 9);
    expect(find.text('新建合集并加入'), findsNothing);
  });

  testWidgets('长列表在固定高度内滚动且末项可达', (tester) async {
    final many = <_Collection>[
      for (var id = 1; id <= 10; id++)
        _Collection(id: id, name: '合集 $id', itemCount: id),
    ];
    final result = await openPicker(tester, collections: AsyncValue.data(many));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test-collection-10')), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-collection-10')), findsOneWidget);

    await tester.tap(find.byKey(const Key('test-collection-10')));
    await tester.pumpAndSettle();
    expect((await result)?.id, 10);
  });

  testWidgets('长名称单行省略，行高与短名称一致', (tester) async {
    const longName = '长名字合集测试-这是一个很长的合集名称用来检查截断';
    await openPicker(
      tester,
      collections: const AsyncValue.data(<_Collection>[
        _Collection(id: 1, name: '后入', itemCount: 7),
        _Collection(id: 2, name: longName, itemCount: 3),
      ]),
    );
    await tester.pumpAndSettle();

    final shortHeight = tester
        .getSize(find.byKey(const Key('test-collection-1')))
        .height;
    final longHeight = tester
        .getSize(find.byKey(const Key('test-collection-2')))
        .height;
    expect(longHeight, shortHeight);

    final longTitle = tester.widget<Text>(find.text(longName));
    expect(longTitle.maxLines, 1);
    expect(longTitle.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('抽屉变体在底部抽屉壳内渲染，新建回调收到 isDrawer', (tester) async {
    var receivedIsDrawer = false;
    await openPicker(
      tester,
      collections: const AsyncValue.data(_collections),
      variant: AppAdaptiveModalVariant.drawer,
      onCreate: (context, isDrawer) async {
        receivedIsDrawer = isDrawer;
        return null;
      },
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test-picker-bottom-sheet')), findsOneWidget);
    await tester.tap(find.text('新建合集并加入'));
    await tester.pumpAndSettle();
    expect(receivedIsDrawer, isTrue);
  });
}
