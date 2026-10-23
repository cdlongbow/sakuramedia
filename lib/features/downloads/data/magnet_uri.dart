/// 评论或任意文本中识别出的磁力链接。
class MagnetLink {
  const MagnetLink({required this.uri, required this.infoHash});

  /// 可直接提交给后端的 `magnet:` URI；HTML 实体已还原、尾部标点已去掉。
  final String uri;

  /// 归一化后的 BTIH，用于去重。
  final String infoHash;
}

/// 从一段文本中提取可提交的磁力链接。
///
/// - 只接受带完整 `xt=urn:btih:`（40 位十六进制或 32 位 Base32）的链接，
///   被换行截断或 hash 不完整的片段会被忽略；
/// - 还原 `&amp;` 等 HTML 实体，避免把转义后的查询参数原样提交；
/// - 去掉链接后紧跟的中英文标点；
/// - 按 BTIH 去重，同一资源的不同 tracker 只保留第一次出现的链接。
List<MagnetLink> extractMagnetLinks(String text) {
  if (text.isEmpty) return const <MagnetLink>[];

  final normalized = _decodeHtmlEntities(text);
  final links = <MagnetLink>[];
  final seenInfoHashes = <String>{};

  for (final match in _magnetPattern.allMatches(normalized)) {
    if (_isPartOfLongerWord(normalized, match.start)) continue;
    final candidate = _trimTrailingPunctuation(match.group(0)!);
    final btih = _btihPattern.firstMatch(candidate);
    if (btih == null) continue;

    final infoHash = btih.group(1)!.toUpperCase();
    final hashEnd = btih.end;
    var uriEnd = candidate.length;
    if (hashEnd < candidate.length) {
      final next = candidate[hashEnd];
      if (_isAsciiAlphanumeric(next)) {
        // 比合法 hash 更长的连续字符，不能截断成看似有效的链接。
        continue;
      }
      if (!_isUriContinuation(next)) {
        // 链接后直接粘了中文或标点：只保留到 hash 结束。
        uriEnd = hashEnd;
      }
    }

    final uri = _trimTrailingPunctuation(candidate.substring(0, uriEnd));
    if (!seenInfoHashes.add(infoHash)) continue;
    links.add(MagnetLink(uri: uri, infoHash: infoHash));
  }

  return links;
}

/// 大小写不敏感地匹配 `magnet:`；调用方会再排除 `xmagnet:` 这类长单词前缀。
final RegExp _magnetPattern = RegExp(
  "magnet:\\?[^\\s<>\"'`]+",
  caseSensitive: false,
);

final RegExp _btihPattern = RegExp(
  r'[?&]xt=urn:btih:([0-9a-fA-F]{40}|[A-Za-z2-7]{32})',
  caseSensitive: false,
);

/// 链接后可能继续出现的合法分隔符；其他字符视为评论正文。
bool _isUriContinuation(String char) => char == '&' || char == '?';

bool _isPartOfLongerWord(String text, int start) {
  if (start == 0) return false;
  return _isAsciiAlphanumericCode(text.codeUnitAt(start - 1));
}

bool _isAsciiAlphanumeric(String char) {
  if (char.isEmpty) return false;
  return _isAsciiAlphanumericCode(char.codeUnitAt(0));
}

bool _isAsciiAlphanumericCode(int code) {
  return (code >= 0x30 && code <= 0x39) ||
      (code >= 0x41 && code <= 0x5a) ||
      (code >= 0x61 && code <= 0x7a);
}

String _decodeHtmlEntities(String text) {
  if (!text.contains('&')) return text;
  return text
      .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
      .replaceAll(RegExp(r'&#0*38;'), '&')
      .replaceAll(RegExp(r'&#x0*26;', caseSensitive: false), '&');
}

const String _trailingPunctuation = '.,;:!?&)]}，。；：！？、）】》」』”’';

String _trimTrailingPunctuation(String value) {
  var end = value.length;
  while (end > 0 && _trailingPunctuation.contains(value[end - 1])) {
    end--;
  }
  return value.substring(0, end);
}
