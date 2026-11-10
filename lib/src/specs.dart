// Numbers from product titles: magazine capacity, barrel length, rounds per
// box and cost per round. Port of gunsnprices/specs.py.
import 'util.dart';

final _space = RegExp(r'\s+');

String _prep(String? text) {
  final s = unescapeHtml(unescapeHtml(text))
      .toLowerCase()
      .replaceAll('”', '"')
      .replaceAll('″', '"')
      .replaceAll('“', '"')
      .replaceAll("''", '"')
      .replaceAll('’’', '"')
      .replaceAll('®', '')
      .replaceAll('™', '');
  return s.replaceAll(_space, ' ');
}

const _num = r'(\d{1,3}(?:,\d{3})+|\d{1,5})';
final _ammo = RegExp(
  r'\b(?:ammo|ammunition|shotshells?|shot ?shells?|cartridges?|bullets?'
  r'|primers?|slugs?|buckshot|pellets?|bbs?|grains?|\d+\s*gr|'
  r'per box|box of|rounds? box|rds?/box)\b'
  r'|/\s*(?:box|bx|pk|pack|case|cs|tin)\b',
);

/// `true` if the title reads like ammunition (bullet weight, "ammo",
/// "20/box", ...) rather than a firearm.
///
/// ```dart
/// looksLikeAmmo('Hornady 9mm 115gr FTX Critical Defense 25rd'); // true
/// ```
bool looksLikeAmmo(String? title) => _ammo.hasMatch(_prep(title));

// --- magazine capacity -------------------------------------------------------

final _capPlus = RegExp(r'(?<![\d.:/x])(\d{1,3})\s*\+\s*1(?!\d)'); // 15+1
final _capRd = RegExp(
  r'(?<![\d.:/x])(\d{1,3})\s*-?\s*(?:rd|rds|rnd|rnds|round|rounds|shot|shots)\b'
  r'(?!\s*/?\s*(?:per\b|box|bx|pack|pk|case))',
);
// "13rd/15rd", "1-30Rd/1-10Rd Mag": ships with magazines of two sizes - take
// the larger one
final _capPair = RegExp(
  r'(?<![\d.:/x])(\d{1,3})\s*-?\s*(?:rd|rds|rnd|rnds|rounds?)?\s*/\s*(?:1?-)?'
  r'(\d{1,3})\s*-?\s*(?:rd|rds|rnd|rnds|rounds?)\b',
);
final _capMag =
    RegExp(r'\b(?:cap|capacity)\s*[:=]?\s*(\d{1,3})\b(?!\s*(?:"|in\b|gr\b))');

/// Magazine capacity of a firearm or magazine from its title ("17RD", "15+1",
/// "10-shot"), or `null`.
///
/// For "15+1" the magazine capacity (15) is returned. Use it on firearm and
/// magazine titles: in ammunition titles "20 rounds" means rounds per box
/// (see [roundsPerBox]).
///
/// ```dart
/// magazineCapacity('Glock 19 Gen5 9mm 4.02in 15+1 Black'); // 15
/// ```
int? magazineCapacity(String? title) {
  final s = _prep(title);
  final p = _capPair.firstMatch(s);
  if (p != null) {
    final a = int.parse(p[1]!);
    final b = int.parse(p[2]!);
    final n = a > b ? a : b;
    if (n >= 1 && n <= 110) return n;
  }
  for (final re in [_capPlus, _capRd, _capMag]) {
    for (final m in re.allMatches(s)) {
      final n = int.parse(m[1]!);
      if (n >= 1 && n <= 110) return n;
    }
  }
  return null;
}

// --- barrel length -----------------------------------------------------------

const _inch = r'(?:"|in\b(?!\s*(?:1\b|stock\b|one\b))\.?|inch(?:es)?\b'
    r'|-inch\b|-in\b)';
const _len = r'(\d{1,2}(?:\.\d{1,3})?)(?:[\s-]+(\d{1,2})/(\d{1,2}))?'; // 16 1/2
const _bbl = r'(?:bbl|brl|barrel)\b';
final _barTagged = [
  // 20" barrel, 22 bbl
  RegExp(r'(?<![\d.:/x#$-])' + _len + r'\s*-?\s*' + _inch + r'?\s*' + _bbl),
  // barrel: 20"
  RegExp(
      r'\b(?:bbl|brl|barrel)\s*(?:length)?\s*[:=]?\s*' + _len + r'\s*' + _inch),
];
final _barInch = RegExp(r'(?<![\d.:/x#$-])' + _len + r'\s*-?\s*' + _inch);
final _notBarrelAfter = RegExp(
  r'\s*-?\s*(?:chamber|chbr|chmbr|shells?|m-?lok|mlok|handguard|hg\b|rail'
  r'|keymod|quad|lop\b|length of pull|oal\b|twist|rate)',
);
final _notBarrelBefore = RegExp(
  r'(?:lop|oal|overall|length of pull|pull|twist|1:|chamber|m-?lok|mlok'
  r'|handguard|rail|sight radius)\s*[:=]?\s*$',
);
final _shotgun = RegExp(
  r'\b(?:\d{1,2}|410)\s*(?:ga|gauge|g)\b|\.410|shotgun|o/u|over/under|sxs'
  r'|side by side|\b(?:12|16|20|28|410)/\d\d\b',
);
// "O/U 12/28": gauge / barrel length (10 is left out: "10/22" is a Ruger
// rifle)
final _gaugeSlash = RegExp(
  r'(?<![a-z0-9./$#-])(?:12|16|20|28|410)/(1[89](?:\.5)?|2\d|3[0-4])'
  r'(?![\d/.])(?!\s*(?:ga|gauge|rd|round))',
);

double _length(Match m) {
  var v = double.parse(m[1]!);
  final num = m[2];
  final den = m[3];
  if (num != null && den != null) {
    final n = int.parse(num);
    final d = int.parse(den);
    if ((d == 2 || d == 4 || d == 8 || d == 16) && n < d) v += n / d;
  }
  return v;
}

/// Barrel length in inches from a firearm title ('4.25"', "16 in",
/// "20-inch", '16 1/2"', "22 BBL"), or `null`.
///
/// Chamber length (3" on shotguns), twist rate, handguard and length-of-pull
/// values are skipped.
///
/// ```dart
/// barrelLength('Mossberg 590 Persuader 12/20 BL/SY 3"'); // 20.0
/// ```
double? barrelLength(String? title) {
  final s = _prep(title);
  for (final re in _barTagged) {
    for (final m in re.allMatches(s)) {
      final v = _length(m);
      if (v >= 1.5 && v <= 36) return v;
    }
  }
  final g = _gaugeSlash.firstMatch(s);
  if (g != null) return double.parse(g[1]!);
  final shotgun = _shotgun.hasMatch(s);
  for (final m in _barInch.allMatches(s)) {
    final v = _length(m);
    if (!(v >= 1.5 && v <= 36)) continue;
    if (_notBarrelAfter.matchAsPrefix(s, m.end) != null ||
        _notBarrelBefore
            .hasMatch(s.substring(m.start < 20 ? 0 : m.start - 20, m.start))) {
      continue;
    }
    if (shotgun && v <= 3.5) continue; // 3" chamber
    return v;
  }
  return null;
}

// --- rounds per box ----------------------------------------------------------

const _b = r'(?<![a-z0-9.#$/])';
final _rpb = [
  RegExp('$_b$_num'
      r'\s*-?\s*(?:rd|rds|round|rounds|rnd|rnds|ct|count|pcs|pc|cartridges'
      r'|shells|shotshells|bullets)\b(?!\s*(?:mag|magazine|capacity|cap)\b)'),
  RegExp('$_b$_num'
      r'\s*(?:/\s*|per\s+)(?:box|bx|pack|pk|case|cs|tin|can|bag|ct)\b'),
  RegExp(r'(?:box|pack|case|tin|bx|bag|can) of\s*' '$_num'),
  RegExp('$_b$_num' r'\s*-?\s*(?:pack|pk|packs)\b'),
];
// distributor notation "50/10", "20/25": rounds per box / boxes per case
final _boxCase = RegExp(
  r'(?<![\d.\-/])(5|10|15|18|20|25|30|40|50|100|200|250|500|1000)\s*/\s*'
  r'(\d{1,3})(?![\d/."])',
);
const _caliberSlash = {
  '30/30', '45/70', '30/06', '22/250', '25/06', '38/55', //
  '44/40', '32/20', '38/40', '25/20', '32/40',
};
const _boxesPerCaseNot = {'2', '4', '8', '16', '32'};

/// Number of rounds in one package of ammunition ("20rds", "50/box",
/// "Box of 25", "1,000 Rounds"), or `null`.
///
/// ```dart
/// roundsPerBox('Federal American Eagle 9mm 115gr FMJ, 50/Box'); // 50
/// ```
int? roundsPerBox(String? title) {
  final s = _prep(title);
  for (final re in _rpb) {
    final m = re.firstMatch(s);
    if (m != null) {
      final digits = m[1]!.replaceAll(',', '');
      // Python ints never overflow; anything this long is out of range anyway
      final n = digits.length > 9 ? 0 : int.parse(digits);
      if (n >= 1 && n <= 20000) return n;
    }
  }
  for (final m in _boxCase.allMatches(s)) {
    if (!_caliberSlash.contains('${m[1]}/${m[2]}') &&
        !_boxesPerCaseNot.contains(m[2])) {
      return int.parse(m[1]!);
    }
  }
  return null;
}

/// Price of one round, rounded to 4 decimals (`null` without a price or a
/// round count).
///
/// ```dart
/// costPerRound(18.99, 50); // 0.3798
/// ```
double? costPerRound(num? price, int? rounds) {
  if (price == null || rounds == null || price <= 0 || rounds <= 0) {
    return null;
  }
  return round4(price / rounds);
}
