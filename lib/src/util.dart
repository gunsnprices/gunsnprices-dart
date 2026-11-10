// Helpers that reproduce the Python standard library functions the reference
// implementation relies on (html.unescape, re.escape, round(x, 4)).
import 'data/entities.g.dart';

final _charref =
    RegExp(r'&(#[0-9]+;?|#[xX][0-9a-fA-F]+;?|[^\t\n\f <&#;]{1,32};?)');

/// Decodes HTML character references exactly like Python's `html.unescape`.
String unescapeHtml(String? s) {
  if (s == null || s.isEmpty) return '';
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(_charref, (m) {
    final ref = m[1]!;
    if (ref.startsWith('#')) {
      final hex = ref[1] == 'x' || ref[1] == 'X';
      var digits = ref.substring(hex ? 2 : 1);
      if (digits.endsWith(';')) digits = digits.substring(0, digits.length - 1);
      final num = _codePoint(digits, hex ? 16 : 10);
      final invalid = invalidCharrefs[num];
      if (invalid != null) return invalid;
      if ((num >= 0xd800 && num <= 0xdfff) || num > 0x10ffff) return '\ufffd';
      if (invalidCodepoints.contains(num)) return '';
      return String.fromCharCode(num);
    }
    final named = html5Entities[ref];
    if (named != null) return named;
    // the longest entity name that starts the reference ("&ampx" -> "&x")
    for (var x = ref.length - 1; x > 1; x--) {
      final head = html5Entities[ref.substring(0, x)];
      if (head != null) return head + ref.substring(x);
    }
    return '&$ref';
  });
}

/// Value of a numeric character reference; anything past U+10FFFF comes back
/// as 0x110000 (Python has big integers, Dart on the web does not).
int _codePoint(String digits, int radix) {
  final d = digits.replaceFirst(RegExp('^0+'), '');
  if (d.isEmpty) return 0;
  if (d.length > (radix == 16 ? 6 : 7)) return 0x110000;
  return int.parse(d, radix: radix);
}

const _special = '()[]{}?*+-|^\$\\.&~# \t\n\r\v\f';

/// Escapes a string for a regular expression the way Python's `re.escape`
/// does (the same characters get a backslash).
String reEscape(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (_special.contains(ch)) b.write('\\');
    b.write(ch);
  }
  return b.toString();
}

final _zeros = RegExp(r'^0*$');

/// Python `round(x, 4)`: correctly rounded, exact ties (0.53125) go to the
/// even digit.
double round4(double x) {
  if (!x.isFinite || x.abs() >= 1e15) return x;
  final s = x.toStringAsFixed(20);
  final dot = s.indexOf('.');
  if (s[dot + 5] == '5' && _zeros.hasMatch(s.substring(dot + 6))) {
    final f = (x * 10000).floor();
    return (f.isEven ? f : f + 1) / 10000;
  }
  return double.parse(x.toStringAsFixed(4));
}

/// Stable sort (Dart's [List.sort] is not guaranteed to be stable; Python's
/// `sorted` is).
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = [for (final (i, x) in items.indexed) (i, x)];
  indexed.sort((a, b) {
    final c = compare(a.$2, b.$2);
    return c != 0 ? c : a.$1 - b.$1;
  });
  return [for (final (_, x) in indexed) x];
}

/// Python template (`\g<1>`, `\1`, `\\`) for [String.replaceAllMapped].
String Function(Match) pythonTemplate(String template) {
  final parts = <Object>[]; // String literal or int group
  final lit = StringBuffer();
  final rx = RegExp(r'\\g<(\d+)>|\\(\d{1,2})|\\(.)');
  var pos = 0;
  for (final m in rx.allMatches(template)) {
    lit.write(template.substring(pos, m.start));
    final g = m[1] ?? m[2];
    if (g != null) {
      parts
        ..add(lit.toString())
        ..add(int.parse(g));
      lit.clear();
    } else {
      final ch = m[3]!;
      lit.write(
          const {'n': '\n', 't': '\t', 'r': '\r', '\\': '\\'}[ch] ?? '\\$ch');
    }
    pos = m.end;
  }
  lit.write(template.substring(pos));
  parts.add(lit.toString());
  return (m) {
    final b = StringBuffer();
    for (final p in parts) {
      b.write(p is int ? (m.group(p) ?? '') : p);
    }
    return b.toString();
  };
}
