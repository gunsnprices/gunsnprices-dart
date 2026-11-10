/// Parse firearm and ammunition product titles into structured data: brand,
/// model, caliber, magazine capacity, barrel length, rounds per box and cost
/// per round.
///
/// This is the title parser behind [GunsNPrices](https://gunsnprices.com), a
/// price comparison site for US gun and ammo stores. The model dictionaries
/// (50 brands) and the caliber list (293 calibers) are the ones the site uses
/// to group listings.
///
/// ```dart
/// import 'package:gunsnprices/gunsnprices.dart';
///
/// final info = parseTitle('Glock 19 Gen 5 MOS 9mm 4.02in 15rd Pistol');
/// info.model?.model;  // Glock 19 Gen 5 MOS
/// info.caliber?.name; // 9×19mm Parabellum
/// info.capacity;      // 15
/// info.barrelLength;  // 4.02
/// ```
///
/// Pure Dart with the data compiled in: works in Flutter, on the web and on
/// the server.
library;

export 'src/calibers.dart'
    show findCaliber, findCalibers, listCalibers, normalizeCaliber;
export 'src/models.dart' show identifyModel, listBrands;
export 'src/parse.dart' show parseTitle;
export 'src/specs.dart'
    show
        barrelLength,
        costPerRound,
        looksLikeAmmo,
        magazineCapacity,
        roundsPerBox;
export 'src/types.dart';

/// Version of this package.
const packageVersion = '0.1.0';
