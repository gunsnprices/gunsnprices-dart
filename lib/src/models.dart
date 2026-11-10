// Identify the firearm model in a product title: brand -> family -> model.
// Port of gunsnprices/models.py; the rules are GunsNPrices' model
// dictionaries (50 brands).
import 'data/models.g.dart';
import 'data/schema.dart';
import 'types.dart';
import 'util.dart';

// airguns and airsoft are not firearms (the site filters them by category;
// here we go by the title)
final _airgun = RegExp(
  r'\bair\s*-?\s*(?:gun|rifle|pistol)s?\b|\bairgun|\bairsoft'
  r'|\bbb\s*(?:gun|pistol|rifle)|\bpellets?\b|\bco2\b',
  caseSensitive: false,
);

// accessories named after a gun ("Glock 19 holster", "Sig P365 XL 12rd
// Magazine", "Magpul PMAG for Glock 19"). A title that describes a gun
// (pistol/rifle/..., "15+1", a barrel length) or mentions the item as
// included ("w/ 3 magazines", "no magazine") is not an accessory.
final _accNoun = RegExp(
  r'\b(?:holsters?|magazines?(?!\s*(?:pattern|compatible|well|release|disconnect'
  r'|safety|catch|cut|tube|extension|fed)\b)|pmags?|slings?|'
  r'grip panels?|scope mounts?|recoil pads?|speed ?loaders?'
  r'|mag(?:azine)? loaders?|cleaning kits?|pouch(?:es)?|snap caps?'
  r'|replacement barrels?|conversion kits?|parts kits?)\b',
);
final _accIncluded = RegExp(
  r'(?:(?:\bw/|\bwith\b|\bwithout\b|\bno\b|\band\b|&|\+|\bincl\w*|\bplus\b'
  r'|\(\d\)|\b[1-9]\b|\btwo\b|\bthree\b|\bfour\b|,|\bor\b|\bextra\b|'
  r'\bspare\b|\bfactory\b|\bfits\b|\btakes\b|\baccepts\b|\buses\b)[^,]{0,14}'
  r'|/\s*)$',
);
final _gunWords = RegExp(
  r'\b(?:pistol|rifle|shotgun|revolver|handgun|carbine|firearm'
  r'|semi-?auto(?:matic)?|bolt[- ]?action|pump|lever[- ]?action'
  r'|single[- ]?shot|o/u|over/under|sxs|sbr|derringer)\b|\d+\+1\b'
  r'|\d+(?:\.\d+)?\s*-?\s*(?:"|in\b|inch)',
);

bool _isAccessory(String title) {
  final t = unescapeHtml(unescapeHtml(title)).toLowerCase();
  if (_gunWords.hasMatch(t)) return false;
  for (final m in _accNoun.allMatches(t)) {
    final from = m.start < 16 ? 0 : m.start - 16;
    if (!_accIncluded.hasMatch(t.substring(from, m.start))) return true;
  }
  return false;
}

const _dashes = {
  '‐': '-', '‑': '-', '–': '-', '—': '-', '“': '"', '”': '"', '’': "'", //
  '|': ' | ', '*': ' ', '®': '', '™': '',
};
final _dashesRe = RegExp('[‐‑–—“”’|*®™]');
final _space = RegExp(r'\s+');
final _nonAlnum = RegExp('[^a-z0-9]+');

String _key(String? s) =>
    unescapeHtml(s).toLowerCase().replaceAll(_nonAlnum, '');

RegExp? _any(List<String> patterns) =>
    patterns.isEmpty ? null : RegExp(patterns.join('|'), caseSensitive: false);

RegExp _ci(String pattern) => RegExp(pattern, caseSensitive: false);

/// A model dictionary with its patterns compiled.
class _Dict {
  _Dict(this.d)
      : rewrite = [
          for (final (k, v) in d.titleRewrite) (_ci(k), pythonTemplate(v)),
        ],
        exclude = _any(d.exclude),
        excludeSoft = _any(d.excludeSoft),
        block = _any(d.otherBrandBlock),
        brandAny = d.brandRx != null
            ? _ci(d.brandRx!)
            : _ci('(?<![a-z])${reEscape(d.brandWord)}(?![a-z])'),
        brandStart = d.brandRx != null ? _ci('^\\W*(?:${d.brandRx})') : null,
        configs = [for (final (k, v) in d.configs) (k, _ci(v))],
        features = [for (final (k, v) in d.features) (k, _ci(v))],
        gens = [for (final (k, v) in d.gens) (k, _ci(v))],
        brandNames = d.brandNames.map(_key).toSet(),
        denyNames = d.denyBrandNames.map(_key).toSet(),
        models = [
          for (final m in d.termModels)
            (
              m,
              _ci(m.match),
              m.notMatch == null ? null : _ci(m.notMatch!),
            ),
        ];

  final ModelDict d;
  final List<(RegExp, String Function(Match))> rewrite;
  final RegExp? exclude;
  final RegExp? excludeSoft;
  final RegExp? block;
  final RegExp brandAny;
  final RegExp? brandStart;
  final List<(String, RegExp)> configs;
  final List<(String, RegExp)> features;
  final List<(String, RegExp)> gens;
  final Set<String> brandNames;
  final Set<String> denyNames;
  final List<(TermModel, RegExp, RegExp?)> models;

  // numeric mode (Glock): codes like 19, 19X, 43X, 20SF
  late final RegExp numeric = _ci(
    '(?<![a-z0-9.])(?:${reEscape(d.brandWord)}\\s*-?\\s*g?\\s*-?\\s*|g)(\\d{2})'
    '(?:(sf|x|c|l|m|s)|\\s(sf|x)(?![a-z0-9]))?(?:g([1-6])(?:us)?|(v))?'
    '(fs|mos|rtf)?(?![a-z0-9&"+/])'
    '(?!\\s*-?\\s*(?:round|rounds|rd|rds|rnd|mag|mags|magazine)\\b)',
  );
  late final RegExp ownStart = _ci('^\\W*${reEscape(d.brandWord)}\\b');
  late final RegExp? bareTokens = d.bareModelTokens.isEmpty
      ? null
      : RegExp('\\b(${d.bareModelTokens.join('|')})\\b');

  bool ownBrand(String? brand) =>
      brand != null && brand.isNotEmpty && brandNames.contains(_key(brand));
}

final List<_Dict> _dicts = [for (final d in modelDicts) _Dict(d)];

String _norm(String? s, _Dict d) {
  var t = unescapeHtml(s).replaceAllMapped(_dashesRe, (m) => _dashes[m[0]]!);
  t = t.toLowerCase().replaceAll(_space, ' ').trim();
  for (final (re, to) in d.rewrite) {
    t = t.replaceAllMapped(re, to);
  }
  return t;
}

/// Brands covered by the model dictionaries (50).
List<String> listBrands() => [for (final d in modelDicts) d.brand];

/// Group [i] of [m], `''` when it did not take part in the match.
String _g(Match m, int i) => m[i] ?? '';

class _Found {
  _Found(this.code, this.num, this.end, {this.mos = false, this.gen = ''});

  final String code;
  final String num;
  final int end;
  final bool mos;
  final String gen;
}

class _Mpn {
  _Mpn(this.code, this.mpn, this.gen);

  final String code;
  final String mpn;
  final String gen;
}

class _Result {
  _Result(this.code, this.family, this.gen, this.configs, this.features,
      this.source);

  final String code;
  final String family;
  final String gen;
  final List<String> configs;
  final List<String> features;
  final ModelSource source;
}

// ---------- numeric mode (Glock): generation from the title or the part number

List<_Found> _findModels(String t, _Dict d) {
  final found = <_Found>[];
  final models = d.d.numericModels;
  for (final m in d.numeric.allMatches(t)) {
    final num = m[1]!.toLowerCase();
    final suf = (_g(m, 2).isNotEmpty ? _g(m, 2) : _g(m, 3)).toUpperCase();
    final code = models.containsKey(num + suf)
        ? num + suf
        : (models.containsKey(num) ? num : '');
    if (code.isEmpty) continue;
    found.add(_Found(
      code,
      num,
      m.end,
      mos: _g(m, 6).toLowerCase() == 'mos',
      gen: _g(m, 4).isNotEmpty ? _g(m, 4) : (_g(m, 5).isNotEmpty ? 'V' : ''),
    ));
  }
  return found;
}

final _mpnInTitle = _ci(
  r'\b(?:gl)?[pue][a-z0-9]\d{3}[a-z0-9-]*|\bg\d{2}c?\d{3}us\b'
  r'|\bg\d{4}[a-z]*aut\b',
);
final _mpnUs = _ci(r'^G(\d{2}C?)([345])(\d{2})US$');
final _mpnAut = _ci(r'^G(\d{2})\d{2}[A-Z]*AUT$');
final _mpnLetter = _ci(r'^(?:GL)?([PUE])([A-Z0-9])(\d{2})(\d)');

_Mpn? _decodeMpn(String name, String mpn, String sku, _Dict d) {
  final models = d.d.numericModels;
  final cands = [
    mpn,
    sku,
    for (final m in _mpnInTitle.allMatches(name)) m[0]!,
  ];
  for (final raw in cands) {
    final c = raw.trim();
    var m = _mpnUs.firstMatch(c);
    if (m != null && models.containsKey(m[1]!.toUpperCase())) {
      return _Mpn(m[1]!.toUpperCase(), c, m[2]!);
    }
    m = _mpnAut.firstMatch(c);
    if (m != null && models.containsKey(m[1])) return _Mpn(m[1]!, c, '');
    m = _mpnLetter.firstMatch(c);
    if (m == null) continue;
    final letter = m[2]!.toUpperCase();
    final num = d.d.mpnModelAlias[m[3]!] ?? m[3]!;
    final code = d.d.mpnLetterModel[letter + num] ?? num;
    if (!models.containsKey(code)) continue;
    return _Mpn(code, c, d.d.mpnLetterGen[letter] ?? '');
  }
  return null;
}

final _leadingCode = RegExp(r'^(\d{2})(x)?\b');
final _genRe = RegExp(
    r'\bgen(?:eration)?\.?\s*-?\s*([1-6])\b|\b([1-6])(?:st|nd|rd|th)\s*gen\b'
    r'|\bg([1-6])\b');
final _vAfter = RegExp(r'^\s*v\b');
final _tbMpn = _ci(r'\d(?:mos)?tb\b');

_Result? _parseNumeric(
    String t, String name, String? brand, String mpn, String sku, _Dict d) {
  final pm = _decodeMpn(name, mpn, sku, d);
  if (pm == null && (d.excludeSoft?.hasMatch(t) ?? false)) return null;
  final own = brand != null && brand.isNotEmpty
      ? d.ownBrand(brand) || pm != null
      : pm != null || d.ownStart.hasMatch(t);
  final models = d.d.numericModels;
  var found = _findModels(t, d);
  if (found.isEmpty && own) {
    final m = _leadingCode.firstMatch(t);
    if (m != null) {
      final code = m[1]! + _g(m, 2).toUpperCase();
      if (models.containsKey(code)) found = [_Found(code, m[1]!, m.end)];
    }
  }
  if (found.isEmpty && own && d.bareTokens != null) {
    final m = d.bareTokens!.firstMatch(t);
    if (m != null) {
      found = [_Found(m[1]!.toUpperCase(), m[1]!.substring(0, 2), m.end)];
    }
  }
  if (!own) {
    if (found.isEmpty) return null;
    if (d.block?.hasMatch(t) ?? false) return null;
  }
  var src = ModelSource.title;
  _Found? first;
  String code;
  if (found.isNotEmpty) {
    first = found.first;
    code = first.code;
    for (final x in found) {
      if (x.num == first.num && x.code.length > code.length) code = x.code;
    }
  } else if (own && pm != null) {
    code = pm.code;
    src = ModelSource.mpn;
  } else {
    return null;
  }
  var gen = '';
  if (first != null && first.gen.isNotEmpty) {
    gen = first.gen;
  } else {
    final m = _genRe.firstMatch(t);
    if (m != null) {
      gen = [_g(m, 1), _g(m, 2), _g(m, 3)].firstWhere((x) => x.isNotEmpty);
    } else if (first != null && _vAfter.hasMatch(t.substring(first.end))) {
      gen = 'V';
    } else if (pm != null && pm.gen.isNotEmpty && pm.code == code) {
      gen = pm.gen;
    }
  }
  if (d.d.noGenModels.contains(code) && gen != 'V') gen = '';
  final configs = [
    for (final (n, re) in d.configs)
      if (re.hasMatch(t) ||
          (n == 'MOS' &&
              ((first != null && first.mos) ||
                  (pm != null && pm.mpn.toLowerCase().contains('mos')))))
        n,
  ];
  final features = [
    for (final (n, re) in d.features)
      if (re.hasMatch(t)) n,
  ];
  if (pm != null &&
      _tbMpn.hasMatch(pm.mpn) &&
      !features.contains('Threaded Barrel')) {
    features.add('Threaded Barrel');
  }
  return _Result(code, models[code]!, gen, configs, features, src);
}

// ---------- terms mode (all other brands): ordered list of model patterns,
// first match wins

_Result? _parseTerms(String t, String? brand, _Dict d) {
  if (brand != null && brand.isNotEmpty && d.denyNames.contains(_key(brand))) {
    return null;
  }
  final own = d.ownBrand(brand) || (d.brandStart?.hasMatch(t) ?? false);
  if (!own) {
    if (!d.brandAny.hasMatch(t)) return null;
    if (d.block?.hasMatch(t) ?? false) return null;
  }
  TermModel? hit;
  for (final (m, match, not) in d.models) {
    if (match.hasMatch(t) && !(not?.hasMatch(t) ?? false)) {
      hit = m;
      break;
    }
  }
  if (hit == null) return null;
  final allowed = d.d.otherBrandModels;
  if (!own && allowed.isNotEmpty && !allowed.contains(hit.name)) return null;
  var gen = '';
  for (final (label, re) in d.gens) {
    if (re.hasMatch(t)) {
      gen = label;
      break;
    }
  }
  final configs = <String>[];
  final implied = d.d.configImpliedByGenFamily;
  for (final (name, re) in d.configs) {
    if (!hit.configs.contains(name)) continue;
    final imp = implied[name]?[hit.family] ?? const <String>[];
    if (re.hasMatch(t) ||
        (gen.isNotEmpty && imp.contains(gen)) ||
        hit.impliedConfigs.contains(name)) {
      configs.add(name);
    }
  }
  final features = [
    for (final (n, re) in d.features)
      if (re.hasMatch(t)) n,
  ];
  return _Result(
      hit.name, hit.family, gen, configs, features, ModelSource.title);
}

/// Which matching dictionary wins: the product's own brand -> brand at the
/// start of the title -> brand mentioned earlier.
(int, int) _rank(String title, _Dict d, String? brand) {
  if (d.ownBrand(brand)) return (0, 0);
  final m = d.brandAny.firstMatch(_norm(title, d));
  if (m != null && m.start <= 2) return (1, 0);
  return (2, m?.start ?? 1000000);
}

final _words = RegExp(r'[a-z0-9.&+]+');

Set<String> _wordSet(String s) =>
    {for (final m in _words.allMatches(s.toLowerCase())) m[0]!};

String _leaf(_Result r, _Dict d) {
  var s = d.d.terms ? r.code : '${d.d.brand} ${r.code}';
  if (r.gen.isNotEmpty) {
    s += d.d.terms || r.gen == 'V' ? ' ${r.gen}' : ' Gen ${r.gen}';
  }
  for (final c in r.configs) {
    // skip a config already spelled out in the name ("Plus Shield" on
    // "S&W M&P Shield Plus")
    final spelled =
        _ci('(?<![a-z0-9])${reEscape(c)}(?![a-z0-9])').hasMatch(s) ||
            _wordSet(s).containsAll(_wordSet(c));
    if (!spelled) s += ' $c';
  }
  final needed = d.d.needed[r.family] ?? const <String>[];
  for (final f in d.d.featureOrder) {
    if (r.features.contains(f) && needed.contains(f)) s += ' $f';
  }
  return s;
}

_Result? _parseOne(
    String title, _Dict d, String? brand, String mpn, String sku) {
  final t = _norm(title, d);
  if (d.exclude?.hasMatch(t) ?? false) return null;
  if (d.d.terms) return _parseTerms(t, brand, d);
  // the numeric dictionary (Glock) only runs when the brand is given or named
  // in the title; otherwise part-number decoding picks up other brands' codes
  if (!(d.ownBrand(brand) || d.brandAny.hasMatch(t))) return null;
  return _parseNumeric(t, title, brand, mpn, sku, d);
}

/// Finds the brand, model family and model in a firearm product title.
///
/// * [title]: product title as a store shows it, for example
///   `"Glock 19 Gen 5 MOS 9mm 4.02in 15rd Pistol PA195S203MOS"`.
/// * [brand]: the manufacturer if you know it (helps with titles that don't
///   name the brand).
/// * [mpn]: manufacturer part number, if known (Glock part numbers encode the
///   model and generation).
/// * [sku]: store SKU, if known.
///
/// Returns `null` when no covered brand/model is recognized. Only firearms
/// are covered: titles of accessories, parts and airguns return `null`.
///
/// ```dart
/// identifyModel('Sig Sauer P365 XL 9mm 3.7" 12+1 Optic Ready')?.model;
/// // Sig Sauer P365 XL
/// identifyModel('GLOCK 9MM PISTOL 15RD', brand: 'Glock', mpn: 'UA4350201')
///     ?.model; // Glock 43
/// ```
ModelMatch? identifyModel(String? title,
    {String? brand, String? mpn, String? sku}) {
  if (title == null ||
      title.isEmpty ||
      _airgun.hasMatch(title) ||
      _isAccessory(title)) {
    return null;
  }
  final hits = <((int, int), _Dict, _Result)>[];
  for (final d in _dicts) {
    final r = _parseOne(title, d, brand, mpn ?? '', sku ?? '');
    if (r != null) hits.add((_rank(title, d, brand), d, r));
  }
  if (hits.isEmpty) return null;
  final (_, d, r) = stableSorted(hits, (a, b) {
    final c = a.$1.$1 - b.$1.$1;
    return c != 0 ? c : a.$1.$2 - b.$1.$2;
  }).first;
  final display = d.d.familyDisplay[r.family] ?? '';
  final family = display.isNotEmpty
      ? display
      : (d.d.terms ? r.family : '${d.d.brand} ${r.family}');
  return ModelMatch(
    brand: d.d.brand,
    family: family,
    model: _leaf(r, d),
    generation: r.gen,
    configs: List.unmodifiable(r.configs),
    features: List.unmodifiable(r.features),
    source: r.source,
  );
}
