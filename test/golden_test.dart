// The same 1,150 real store titles and answers as the Python package's
// tests/golden.jsonl (and the JavaScript port's test/golden.jsonl).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:gunsnprices/gunsnprices.dart';
import 'package:test/test.dart';

Map<String, Object?> compact(ProductInfo info) {
  final m = info.model;
  return {
    'kind': info.kind.name,
    'brand': info.brand,
    'model': m == null
        ? null
        : [
            m.family,
            m.model,
            m.generation,
            m.configs,
            m.features,
            m.source.name,
          ],
    'calibers': [for (final c in info.calibers) c.id],
    'capacity': info.capacity,
    'barrel_length': info.barrelLength,
    'rounds': info.rounds,
    'cost_per_round': info.costPerRound,
  };
}

/// JSON equality where 26 == 26.0 (Python writes floats as 26.0).
bool same(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!same(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    return a.keys.every((k) => b.containsKey(k) && same(a[k], b[k]));
  }
  return a == b;
}

void main() {
  final cases = File('test/golden.jsonl')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  test('golden: ${cases.length} titles parse exactly like the Python package',
      () {
    final failures = <String>[];
    for (final c in cases) {
      final a = c['args'] as Map<String, dynamic>;
      final got = compact(parseTitle(
        a['title'] as String,
        brand: a['brand'] as String?,
        mpn: a['mpn'] as String?,
        sku: a['sku'] as String?,
        price: a['price'] as num?,
      ));
      if (!same(got, c['expected'])) {
        failures.add('${a['title']}\n'
            '    expected ${jsonEncode(c['expected'])}\n'
            '    got      ${jsonEncode(got)}');
      }
    }
    printOnFailure(failures.take(15).join('\n'));
    print('golden: ${cases.length - failures.length}/${cases.length} pass');
    expect(failures, isEmpty, reason: '${failures.length} mismatches');
  });
}
