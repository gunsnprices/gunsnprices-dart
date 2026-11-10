/// Kind of cartridge a [Caliber] is.
enum CaliberType {
  /// Pistol and revolver cartridges (9mm, .45 ACP, .357 Mag).
  handgun,

  /// Centerfire rifle cartridges (.308 Win, 6.5 Creedmoor).
  rifle,

  /// Rimfire cartridges (.22 LR, .22 WMR, .17 HMR).
  rimfire,

  /// Shotgun gauges and bores (12 Gauge, .410 Bore).
  shotgun,

  /// Airgun calibers (.177, .22 pellets).
  airgun,

  /// Muzzleloader calibers (.50 cal).
  muzzleloader,
}

/// A caliber (cartridge) from the GunsNPrices caliber list.
class Caliber {
  /// Creates a caliber. You normally get calibers from `findCalibers()`,
  /// `normalizeCaliber()` or `listCalibers()` instead.
  const Caliber({
    required this.id,
    required this.name,
    required this.type,
    this.url = '',
  });

  /// Stable id, for example `9x19mmparabellum`.
  final String id;

  /// Display name, for example `9×19mm Parabellum`.
  final String name;

  /// Handgun, rifle, rimfire, shotgun, airgun or muzzleloader.
  final CaliberType type;

  /// GunsNPrices page comparing ammo prices for this caliber (`''` if none).
  final String url;

  /// JSON-friendly map: `{id, name, type, url}`.
  Map<String, Object?> toJson() =>
      {'id': id, 'name': name, 'type': type.name, 'url': url};

  @override
  bool operator ==(Object other) => other is Caliber && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Caliber($id, $name)';
}

/// Where a [ModelMatch] came from.
enum ModelSource {
  /// The model was read from the product title.
  title,

  /// The model was decoded from the manufacturer part number (Glock).
  mpn,
}

/// A firearm model found by `identifyModel()`.
class ModelMatch {
  /// Creates a model match. You normally get one from `identifyModel()`.
  const ModelMatch({
    required this.brand,
    required this.family,
    required this.model,
    this.generation = '',
    this.configs = const [],
    this.features = const [],
    this.source = ModelSource.title,
  });

  /// Brand as named on GunsNPrices, for example `Glock`.
  final String brand;

  /// Model family, for example `Glock 19`.
  final String family;

  /// The most specific model, for example `Glock 19 Gen 5 MOS`.
  final String model;

  /// Generation (`5`, `V`, `V3` ...) or `''` when unknown.
  final String generation;

  /// Configurations found, for example `[MOS]` or `[Compact]`.
  final List<String> configs;

  /// Features found, for example `[Threaded Barrel, FDE]`.
  final List<String> features;

  /// [ModelSource.title], or [ModelSource.mpn] when a Glock part number was decoded.
  final ModelSource source;

  /// JSON-friendly map with the same keys as the Python package.
  Map<String, Object?> toJson() => {
        'brand': brand,
        'family': family,
        'model': model,
        'generation': generation,
        'configs': configs,
        'features': features,
        'source': source.name,
      };

  @override
  bool operator ==(Object other) =>
      other is ModelMatch &&
      other.brand == brand &&
      other.family == family &&
      other.model == model &&
      other.generation == generation &&
      _listEquals(other.configs, configs) &&
      _listEquals(other.features, features) &&
      other.source == source;

  @override
  int get hashCode => Object.hash(brand, family, model, generation,
      Object.hashAll(configs), Object.hashAll(features), source);

  @override
  String toString() => 'ModelMatch($model)';
}

/// Whether a title is a firearm or ammunition.
enum ProductKind {
  /// Guns: pistols, rifles, shotguns, revolvers.
  firearm,

  /// Ammunition: cartridges, shotshells.
  ammo,
}

/// Result of `parseTitle()`. Fields that don't apply or weren't found are
/// `null` (or empty).
class ProductInfo {
  /// Creates a result. You normally get one from `parseTitle()`.
  const ProductInfo({
    required this.title,
    required this.kind,
    this.brand = '',
    this.model,
    this.calibers = const [],
    this.capacity,
    this.barrelLength,
    this.rounds,
    this.costPerRound,
  });

  /// The title that was parsed.
  final String title;

  /// Firearm or ammo.
  final ProductKind kind;

  /// Brand of the identified model, else the `brand` argument, else `''`.
  final String brand;

  /// The firearm model (firearms only).
  final ModelMatch? model;

  /// Every caliber in the title, in order ("357 Mag / 38 Special").
  final List<Caliber> calibers;

  /// The first caliber in the title.
  Caliber? get caliber => calibers.isEmpty ? null : calibers.first;

  /// Magazine capacity (firearms only). For "15+1" it is 15.
  final int? capacity;

  /// Barrel length in inches (firearms only).
  final double? barrelLength;

  /// Rounds per box (ammo only).
  final int? rounds;

  /// Price of one round (ammo only, needs `price`).
  final double? costPerRound;

  /// JSON-friendly map with the same keys as the Python package
  /// (`barrel_length`, `cost_per_round`).
  Map<String, Object?> toJson() => {
        'title': title,
        'kind': kind.name,
        'brand': brand,
        'model': model?.toJson(),
        'caliber': caliber?.toJson(),
        'calibers': [for (final c in calibers) c.toJson()],
        'capacity': capacity,
        'barrel_length': barrelLength,
        'rounds': rounds,
        'cost_per_round': costPerRound,
      };

  @override
  String toString() => 'ProductInfo(${toJson()})';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
