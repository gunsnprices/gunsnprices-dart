// Shapes of the generated data in lib/src/data/*.g.dart (internal, not
// exported). Field names follow the JSON keys of the Python package data.
import '../types.dart';

/// One caliber of the GunsNPrices caliber list, with the spellings stores use.
class CaliberRecord {
  /// Creates a record (generated code only).
  const CaliberRecord(
    this.caliber, {
    required this.siteName,
    required this.aliases,
    required this.n,
  });

  /// The public caliber object.
  final Caliber caliber;

  /// Name used on gunsnprices.com.
  final String siteName;

  /// Retailer spellings.
  final List<String> aliases;

  /// Number of GunsNPrices listings with this caliber (decides ambiguous
  /// spellings).
  final int n;
}

/// One model of a "terms" dictionary: ordered patterns, the first match wins.
class TermModel {
  /// Creates a model rule (generated code only).
  const TermModel({
    required this.name,
    required this.family,
    required this.match,
    this.notMatch,
    this.configs = const [],
    this.impliedConfigs = const [],
  });

  /// Model name, for example `Sig Sauer P365 XL`.
  final String name;

  /// Family key.
  final String family;

  /// Pattern that selects the model.
  final String match;

  /// Pattern that vetoes the model.
  final String? notMatch;

  /// Configurations that may be added to the model name.
  final List<String> configs;

  /// Configurations the model always has.
  final List<String> impliedConfigs;
}

/// The model dictionary of one brand.
class ModelDict {
  /// Creates a dictionary (generated code only).
  const ModelDict({
    required this.brand,
    required this.terms,
    required this.brandWord,
    this.brandRx,
    this.titleRewrite = const [],
    this.exclude = const [],
    this.excludeSoft = const [],
    this.otherBrandBlock = const [],
    this.otherBrandModels = const [],
    this.termModels = const [],
    this.numericModels = const {},
    this.configs = const [],
    this.features = const [],
    this.gens = const [],
    this.featureOrder = const [],
    this.brandNames = const [],
    this.denyBrandNames = const [],
    this.familyDisplay = const {},
    this.needed = const {},
    this.configImpliedByGenFamily = const {},
    this.mpnLetterGen = const {},
    this.mpnLetterModel = const {},
    this.mpnModelAlias = const {},
    this.noGenModels = const [],
    this.bareModelTokens = const [],
  });

  /// Brand as named on GunsNPrices.
  final String brand;

  /// `true` for "terms" dictionaries, `false` for the numeric one (Glock).
  final bool terms;

  /// Brand word used in titles.
  final String brandWord;

  /// Pattern that finds the brand in a title.
  final String? brandRx;

  /// (pattern, Python replacement template), applied in order.
  final List<(String, String)> titleRewrite;

  /// Titles matching any of these are not this brand's firearms.
  final List<String> exclude;

  /// Like [exclude], unless a part number identifies the gun.
  final List<String> excludeSoft;

  /// When the brand is only mentioned ("for Glock"), these veto a match.
  final List<String> otherBrandBlock;

  /// Models that may be matched when the brand is only mentioned.
  final List<String> otherBrandModels;

  /// Terms mode: ordered model rules.
  final List<TermModel> termModels;

  /// Numeric mode: model code -> family code.
  final Map<String, String> numericModels;

  /// (configuration, pattern), in order.
  final List<(String, String)> configs;

  /// (feature, pattern), in order.
  final List<(String, String)> features;

  /// (generation label, pattern), in order.
  final List<(String, String)> gens;

  /// Order of features in model names.
  final List<String> featureOrder;

  /// Manufacturer names that mean this brand.
  final List<String> brandNames;

  /// Manufacturer names that are never this brand.
  final List<String> denyBrandNames;

  /// Family key -> display name.
  final Map<String, String> familyDisplay;

  /// Family -> features that are part of the model name.
  final Map<String, List<String>> needed;

  /// Configuration -> family -> generations that imply it.
  final Map<String, Map<String, List<String>>> configImpliedByGenFamily;

  /// Glock part numbers: letter -> generation.
  final Map<String, String> mpnLetterGen;

  /// Glock part numbers: letter + number -> model code.
  final Map<String, String> mpnLetterModel;

  /// Glock part numbers: number -> model number.
  final Map<String, String> mpnModelAlias;

  /// Models without generations.
  final List<String> noGenModels;

  /// Model codes recognized without the brand word.
  final List<String> bareModelTokens;
}
