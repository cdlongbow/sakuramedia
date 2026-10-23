import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/downloads/data/magnet_uri.dart';

void main() {
  const hash = '0123456789abcdef0123456789abcdef01234567';

  test('extracts a magnet link and decodes HTML entities', () {
    final links = extractMagnetLinks(
      '这个可以看 magnet:?xt=urn:btih:$hash&amp;dn=movie 谢谢',
    );

    expect(links, hasLength(1));
    expect(links.single.uri, 'magnet:?xt=urn:btih:$hash&dn=movie');
    expect(links.single.infoHash, hash.toUpperCase());
  });

  test('trims trailing punctuation and text glued to the hash', () {
    final links = extractMagnetLinks(
      'magnet:?xt=urn:btih:$hash，下载看看。'
      '另一个 magnet:?xt=urn:btih:$hash试试',
    );

    expect(links, hasLength(1));
    expect(links.single.uri, 'magnet:?xt=urn:btih:$hash');
  });

  test('trims a dangling query separator', () {
    final links = extractMagnetLinks('magnet:?xt=urn:btih:$hash&');

    expect(links, hasLength(1));
    expect(links.single.uri, 'magnet:?xt=urn:btih:$hash');
  });

  test('deduplicates by BTIH and keeps the first URI', () {
    final links = extractMagnetLinks(
      'magnet:?xt=urn:btih:$hash&tr=udp://a\n'
      'magnet:?xt=urn:btih:${hash.toUpperCase()}&tr=udp://b',
    );

    expect(links, hasLength(1));
    expect(links.single.uri, 'magnet:?xt=urn:btih:$hash&tr=udp://a');
  });

  test('accepts base32 BTIH and uppercase scheme', () {
    const base32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final links = extractMagnetLinks('MAGNET:?XT=URN:BTIH:$base32');

    expect(links, hasLength(1));
    expect(links.single.infoHash, base32);
  });

  test('ignores incomplete or embedded magnet fragments', () {
    final links = extractMagnetLinks(
      'magnet:?xt=urn:btih:0123456789abcdef0123456789abcdef0123456\n'
      'xmagnet:?xt=urn:btih:$hash\n'
      'magnet:?dn=no-hash',
    );

    expect(links, isEmpty);
  });

  test('ignores a hash longer than a valid BTIH', () {
    final links = extractMagnetLinks('magnet:?xt=urn:btih:${hash}abcdef');

    expect(links, isEmpty);
  });
}
