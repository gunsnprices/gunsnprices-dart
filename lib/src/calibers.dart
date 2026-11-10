// Recognize firearm calibers in product titles and normalize caliber fields.
// Port of gunsnprices/calibers.py; see that file for the reasoning behind
// each rule.
import 'data/calibers.g.dart';
import 'types.dart';
import 'util.dart';

// word -> spellings used in titles. A word marked optional may be left out
// ("300 Blackout" for ".300 AAC Blackout").
const _syn = <String, List<String>>{
  'win': ['win', 'winchester'],
  'winchester': ['winchester', 'win'],
  'rem': ['rem', 'remington'],
  'remington': ['remington', 'rem'],
  'mag': ['mag', 'magnum'],
  'magnum': ['magnum', 'mag'],
  'wby': ['wby', 'weatherby'],
  'weatherby': ['weatherby', 'wby'],
  'spl': ['spl', 'special'],
  'special': ['special', 'spl'],
  'sprg': ['sprg', 'springfield', 'spfd'],
  'springfield': ['springfield', 'sprg', 'spfd'],
  'government': ['government', 'govt', 'gov'],
  'acp': ['acp', 'auto'],
  'auto': ['auto', 'acp'],
  's&w': [
    's&w',
    's & w',
    'sw',
    'smith & wesson',
    'smith and wesson',
    'smith&wesson'
  ],
  'blackout': ['blackout', 'blk', 'black out'],
  'creedmoor': ['creedmoor', 'creed', 'cm', 'crd', 'creedmore'],
  'parabellum': ['parabellum', 'para', 'luger'],
  'gauge': ['gauge', 'ga', 'gauges'],
  'bore': ['bore', 'ga', 'gauge'],
  'lr': ['lr', 'long rifle'],
  'h&h': ['h&h', 'h & h', 'holland & holland', 'holland and holland'],
  'h&r': ['h&r', 'h & r'],
  'bm': ['bm', 'bushmaster', 'bush'],
};
const _optional = {
  'aac',
  'nato',
  'win',
  'winchester',
  'rem',
  'remington',
  'sprg',
  'springfield',
  'government',
};
const _sep = r'[\s\-]*';

// common title spellings that the synonym table does not produce
const _extra = <String, List<String>>{
  '.300 AAC Blackout': [
    '300 aac',
    '300 bo',
    '300 black out',
    '300 blackout',
    '300 blk'
  ],
  '6.5mm Creedmoor': [
    '6.5 creedmoor',
    '6.5 crd',
    '6.5 cm',
    '6.5mm cm',
    '6.5 cr'
  ],
  '6mm Creedmoor': ['6 creedmoor'],
  '.22 LR': ['22lr', '22 lr', '22 long rifle'],
  '.22 WMR': ['22 mag', '22 magnum', '22 win mag', '22 wmr'],
  '5.56×45mm NATO': [
    '5.56 nato',
    '5.56mm nato',
    '556 nato',
    '5.56x45',
    '5.56',
    '5.56mm',
    '5.56 mm'
  ],
  '7.62x51mm NATO': ['7.62 nato', '7.62mm nato', '762 nato', '762x51'],
  '7.62x39mm': ['762x39'],
  '.410 Bore': ['410 ga', '410 gauge', '410 bore'],
  '.45 Colt': ['45 lc', '45 long colt'],
  '.44 S&W Special': ['44 spl', '44 special', '44 spcl'],
  '.38 S&W Special': [
    '38 spl',
    '38 special',
    '38 spcl',
    '38 spc',
    '38 sp',
    '38 spp',
    '38+p'
  ],
  '.357 Mag': [
    '357 rm',
    '357 rem mag',
    '357 rem magnum',
    '357 remington magnum',
    '357 remington mag'
  ],
  '9×19mm Parabellum': ['9mm luger', '9mm para', '9 mm luger', '9mm'],
  '10mm Auto': ['10mm', '10 mm'],
  '.45 ACP': ['45 acp', '45 auto', '45 automatic', '45 automatic colt pistol'],
  '.40 S&W': ['40 s&w', '40 sw', '40 cal', '40s', '.40'],
  '.380 ACP': ['380 acp', '380 auto', '380'],
  '.243 Win': ['243', '.243'],
  '.308 Win': ['308', '.308'],
  '.350 Legend': ['.350', '350 leg', '350 lgnd', '350 lgd'],
  '.450 BM': ['450 bushmaster', '450 bush'],
  '.204 Ruger': ['.204'],
  '.177': ['177', '.177'],
  '.300 Win Mag': ['300 wm'],
  '7mm Remington Magnum': ['7mm rm', '7 rm', '7mm rem mag'],
  '.338 Lapua Mag': ['338 lapua', '338 lap'],
  '.30 Carbine': ['30 m1', '30 m1 carbine'],
  '.30-06 Springfield': ['30-06 sp'],
  '7.92×57mm Mauser': ['8x57', '8x57mm', '8x57 js', '8x57 is'],
  '.50 AE': ['50 action express'],
  '12 Gauge': ['12 ga', '12ga', '12 gauge', '12-gauge', '12g'],
  '20 Gauge': ['20 ga', '20ga', '20 gauge', '20-gauge', '20g'],
  '16 Gauge': ['16 ga', '16ga', '16 gauge', '16g'],
  '28 Gauge': ['28 ga', '28ga', '28 gauge', '28g'],
  '10 Gauge': ['10g'],
};

// a bare number or "Nmm" in a title is usually something else, not a caliber;
// these exceptions were checked against GunsNPrices listings
final _bare = RegExp(r'^\.?\d+(?:\.\d+)?(?:\s*mm)?$');
const _allowBare = {
  '380', '410', '9mm', '10mm', '10 mm', '5.56', '5.56mm', '5.56 mm', //
  '243', '.243', '308', '.308', '.40', '.350', '.204', '177', '.177',
};
// "12g" next to CO2 is a 12-gram CO2 cartridge, not 12 gauge
final _gram = RegExp(r'^\d+\s?g$');
// shotguns "O/U 12/28": gauge / barrel length; on ammo "20/25" is rounds per
// box / boxes per case
final _context = <(RegExp, String)>[
  (
    RegExp(r'(?<![a-z0-9./$#-])12/(?:1[89]|2\d|3[0-4])(?:\.5)?(?![\d/.])'
        r'(?!\s*(?:ga|gauge|rd|round))'),
    '12gauge'
  ),
  (
    RegExp(r'(?<![a-z0-9./$#-])20/(?:18|18\.5|2[0-46-9]|3[0-2])(?![\d/.])'
        r'(?!\s*(?:ga|gauge|rd|round))'),
    '20gauge'
  ),
  (
    RegExp(r'(?<![a-z0-9./$#-])28/(?:2[6-9]|3[0-2])(?![\d/.])'
        r'(?!\s*(?:ga|gauge|rd|round))'),
    '28gauge'
  ),
  (RegExp(r'(?<![a-z0-9.$#-])\.?357(?=\s*/\s*\.?38)'), '357mag'),
];

final _digitDot = RegExp(r'(?<=\d)\.(?=\d)');
final _notKeyChar = RegExp('[^a-z0-9#&]+');

/// Lookup key of a caliber spelling: "9mm Luger" -> "9mmluger".
String caliberKey(String? s) {
  var t = unescapeHtml(s).toLowerCase().replaceAll('×', 'x').replaceAll(
        'х',
        'x',
      );
  t = t.replaceAll(_digitDot, '#').replaceAll(_notKeyChar, '');
  return t.replaceAll('#', '.').replaceAll('&', 'and');
}

final _space = RegExp(r'\s+');

List<String> _tokens(String name) {
  final s = unescapeHtml(name)
      .toLowerCase()
      .replaceAll('×', 'x')
      .replaceFirst(RegExp(r'^\.'), '');
  return s.trim().split(_space).where((t) => t.isNotEmpty).toList();
}

final _metricPair = RegExp(r'^\.?\d+(?:\.\d+)?x\d+mm[a-z]*$');
final _metric = RegExp(r'^\d+mm$');

List<String> _tokenAlts(String tok) {
  if (_metricPair.hasMatch(tok)) return [tok, tok.replaceAll('mm', '')];
  if (_metric.hasMatch(tok)) {
    return [tok, '${tok.substring(0, tok.length - 2)} mm'];
  }
  final alts = [
    ...(_syn[tok] ?? [tok])
  ];
  if (_optional.contains(tok)) alts.add('');
  return alts;
}

List<String> _variants(String name) {
  final toks = _tokens(name);
  if (toks.isEmpty || name.contains('/')) return [];
  final lists = toks.map(_tokenAlts).toList();
  final out = <String>{};
  // itertools.product order (last list varies fastest), first 400 combinations
  final idx = List.filled(lists.length, 0);
  for (var n = 0; n < 400; n++) {
    final v = [for (var k = 0; k < lists.length; k++) lists[k][idx[k]]]
        .where((x) => x.isNotEmpty)
        .join(' ');
    if (v.isNotEmpty && (!_bare.hasMatch(v) || _allowBare.contains(v))) {
      out.add(v);
    }
    var k = lists.length - 1;
    while (k >= 0 && ++idx[k] == lists[k].length) {
      idx[k--] = 0;
    }
    if (k < 0) break;
  }
  return out.toList()..sort();
}

final _digitXDigit = RegExp(r'(?<=\d)x(?=\d)');
final _startsWithDigit = RegExp(r'^\d');

String _rx(String variant) {
  final parts = variant.split(' ').map((tok) {
    final t = reEscape(tok).replaceAll(_digitXDigit, r'\s*x\s*');
    return t.split(r'\-').join(_sep);
  });
  final body = parts.join(_sep);
  return _startsWithDigit.hasMatch(variant) ? r'\.?' + body : body;
}

class _Index {
  _Index(this.byKey, this.big, this.byId);

  final Map<String, Caliber> byKey;
  final RegExp big;
  final Map<String, Caliber> byId;
}

final _Index _index = _buildIndex();

_Index _buildIndex() {
  final byId = <String, Caliber>{};
  final conflict = <String, List<(int, Caliber)>>{};
  final pats = <String, String>{};
  final hasDigit = RegExp(r'\d');
  for (final rec in caliberRecords) {
    final cal = rec.caliber;
    byId[cal.id] = cal;
    final names = [
      cal.name,
      rec.siteName,
      ...rec.aliases,
      ...?_extra[cal.name],
    ];
    for (final n in names) {
      final own = unescapeHtml(n).toLowerCase();
      final vs = _variants(n);
      if (!_bare.hasMatch(own) || _allowBare.contains(own)) vs.add(own);
      for (final v in vs) {
        final k = caliberKey(v);
        if (k.isEmpty || !hasDigit.hasMatch(k)) continue;
        final list = conflict.putIfAbsent(k, () => []);
        if (list.every((x) => x.$2.id != cal.id)) list.add((rec.n, cal));
        pats.putIfAbsent(
            k, () => v != own || !v.contains('/') ? _rx(v) : reEscape(v));
      }
    }
  }
  final byKey = <String, Caliber>{};
  for (final MapEntry(key: k, value: cands) in conflict.entries) {
    final sorted = stableSorted(cands, (a, b) => b.$1 - a.$1);
    // one spelling, several calibers: keep the one with 10x+ more listings,
    // otherwise the spelling is ambiguous
    if (sorted.length == 1 ||
        sorted[0].$1 >= 10 * (sorted[1].$1 < 1 ? 1 : sorted[1].$1)) {
      byKey[k] = sorted[0].$2;
    }
  }
  final keys =
      stableSorted(byKey.keys, (a, b) => pats[b]!.length - pats[a]!.length);
  final big = RegExp(
    r'(?<![a-z0-9.$])(?:' +
        keys.map((k) => pats[k]).join('|') +
        r')(?![a-z0-9])',
    caseSensitive: false,
  );
  return _Index(byKey, big, byId);
}

String _prep(String? text) {
  final s = unescapeHtml(text)
      .toLowerCase()
      .replaceAll('×', 'x')
      .replaceAll('”', '"')
      .replaceAll('″', '"')
      .replaceAll('®', '')
      .replaceAll('™', '');
  return s.replaceAll(_space, ' ');
}

/// All calibers mentioned in [text], in order of appearance, without
/// duplicates.
///
/// ```dart
/// findCalibers('Ruger GP100 .357 Mag / .38 Special 4.2in Revolver')
///     .map((c) => c.name); // (.357 Mag, .38 S&W Special)
/// ```
List<Caliber> findCalibers(String? text) {
  final index = _index;
  final s = _prep(text);
  final co2 = s.contains('co2');
  final hits = <(int, Caliber)>[];
  for (final m in index.big.allMatches(s)) {
    if (co2 && _gram.hasMatch(m[0]!)) continue;
    final c = index.byKey[caliberKey(m[0])];
    if (c != null) hits.add((m.start, c));
  }
  for (final (re, id) in _context) {
    for (final m in re.allMatches(s)) {
      hits.add((m.start, index.byId[id]!));
    }
  }
  final out = <Caliber>[];
  final seen = <String>{};
  for (final (_, c) in stableSorted(hits, (a, b) => a.$1 - b.$1)) {
    if (seen.add(c.id)) out.add(c);
  }
  return out;
}

/// The first caliber mentioned in [text], or `null`.
Caliber? findCaliber(String? text) {
  final found = findCalibers(text);
  return found.isEmpty ? null : found.first;
}

/// Normalizes a caliber field ("9mm Luger", "5.56 NATO", "12 GA") to a
/// [Caliber].
///
/// The whole value is looked up first; if it isn't a known spelling, the
/// first caliber found inside it is returned.
///
/// ```dart
/// normalizeCaliber('308 WIN (7.62X51 NATO)')?.name; // .308 Win
/// ```
Caliber? normalizeCaliber(String? value) =>
    _index.byKey[caliberKey(value)] ?? findCaliber(value);

/// The full caliber list (293 calibers), sorted by name.
List<Caliber> listCalibers() =>
    stableSorted(_index.byId.values, (a, b) => a.name.compareTo(b.name));
