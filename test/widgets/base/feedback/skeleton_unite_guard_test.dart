import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 卡片骨架合并必须走 `AppSkeletonUnite`，理由见 `app_skeletonizer.dart`：
/// skeletonizer 合并骨块时取合并区内「最大后代」的圆角，卡内药丸角标用的是
/// `appRadius.pillBorder`（`BorderRadius.circular(999)`），一旦它成为最大后代，
/// 整张卡会被画成椭圆——影片卡的热度胶囊踩过这个坑。
const String _allowedFile = 'lib/widgets/base/feedback/app_skeletonizer.dart';

const String _call = 'Skeleton.unite(';

void main() {
  test('Skeleton.unite 只能由 AppSkeletonUnite 显式传圆角使用', () {
    final files =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    final violations = <String>[];
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      final source = file.readAsStringSync();
      for (final arguments in _findCallArguments(source, _call)) {
        if (path != _allowedFile) {
          violations.add('$path: 禁止直接调用 Skeleton.unite，请改用 AppSkeletonUnite');
        } else if (!arguments.contains('borderRadius:')) {
          violations.add('$path: Skeleton.unite 必须显式传 borderRadius');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

/// 返回源码里每个 `call` 调用的参数文本（不含括号），跳过注释行。
List<String> _findCallArguments(String source, String call) {
  final results = <String>[];
  var index = source.indexOf(call);
  while (index != -1) {
    final lineStart = source.lastIndexOf('\n', index) + 1;
    final line = source.substring(lineStart, index).trimLeft();
    var nextStart = index + call.length;
    if (!line.startsWith('//')) {
      final open = index + call.length - 1;
      final close = _matchingParen(source, open);
      if (close != null) {
        results.add(source.substring(open + 1, close));
        nextStart = close + 1;
      }
    }
    index = nextStart >= source.length ? -1 : source.indexOf(call, nextStart);
  }
  return results;
}

/// 从 `open`（指向 `(`）出发找到配对的 `)`，找不到返回 null。
int? _matchingParen(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final char = source.codeUnitAt(i);
    if (char == _leftParen) {
      depth++;
    } else if (char == _rightParen) {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return null;
}

const int _leftParen = 0x28;
const int _rightParen = 0x29;
