// One call for everything: parse a firearm or ammunition product title.
// Port of gunsnprices/parse.py.
import 'calibers.dart';
import 'models.dart';
import 'specs.dart';
import 'types.dart';

/// Parses a product title into brand, model, calibers, magazine capacity,
/// barrel length, rounds per box and cost per round.
///
/// * [title]: product title as a store shows it.
/// * [brand]: manufacturer, if known.
/// * [mpn]: manufacturer part number, if known.
/// * [sku]: store SKU, if known.
/// * [price]: price of the listing; with ammo it gives
///   [ProductInfo.costPerRound].
/// * [kind]: firearm or ammo; guessed from the title when omitted.
///
/// ```dart
/// final gun = parseTitle('Glock 19 Gen5 MOS 9mm 4.02in 15+1 Black');
/// gun.model?.model;  // Glock 19 Gen 5 MOS
/// gun.caliber?.name; // 9×19mm Parabellum
/// gun.capacity;      // 15
/// gun.barrelLength;  // 4.02
///
/// final ammo = parseTitle('Federal American Eagle 9mm Luger 115gr FMJ, 50/Box',
///     price: 18.99);
/// ammo.kind;         // ProductKind.ammo
/// ammo.rounds;       // 50
/// ammo.costPerRound; // 0.3798
/// ```
ProductInfo parseTitle(
  String? title, {
  String? brand,
  String? mpn,
  String? sku,
  num? price,
  ProductKind? kind,
}) {
  final t = title ?? '';
  final k = kind ?? (looksLikeAmmo(t) ? ProductKind.ammo : ProductKind.firearm);
  final calibers = List<Caliber>.unmodifiable(findCalibers(t));
  if (k == ProductKind.ammo) {
    final rounds = roundsPerBox(t);
    return ProductInfo(
      title: t,
      kind: k,
      brand: brand ?? '',
      calibers: calibers,
      rounds: rounds,
      costPerRound:
          price != null && price != 0 ? costPerRound(price, rounds) : null,
    );
  }
  final model = identifyModel(t, brand: brand, mpn: mpn, sku: sku);
  return ProductInfo(
    title: t,
    kind: k,
    brand: model?.brand ?? brand ?? '',
    model: model,
    calibers: calibers,
    capacity: magazineCapacity(t),
    barrelLength: barrelLength(t),
  );
}
