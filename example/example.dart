// Run: dart run example/example.dart
import 'package:gunsnprices/gunsnprices.dart';

void main() {
  // A firearm: brand, model, caliber, capacity and barrel length.
  final gun = parseTitle('Glock 19 Gen 5 MOS 9mm 4.02in 15rd Pistol');
  print(gun.model?.model); // Glock 19 Gen 5 MOS
  print(gun.caliber?.name); // 9×19mm Parabellum
  print(gun.capacity); // 15
  print(gun.barrelLength); // 4.02

  // Ammunition: rounds per box and, with a price, cost per round.
  final ammo = parseTitle(
    'Federal American Eagle 5.56x45mm 55gr FMJ 1000 Rounds',
    price: 449.99,
  );
  print('${ammo.kind.name}: ${ammo.caliber?.name}, ${ammo.rounds} rounds, '
      '\$${ammo.costPerRound} per round'); // ammo: 5.56×45mm NATO, 1000 rounds, $0.45 per round

  // Glock part numbers are decoded when the title says nothing useful.
  final m =
      identifyModel('GLOCK 9MM PISTOL 15RD', brand: 'Glock', mpn: 'UA4350201');
  print('${m?.model} (from ${m?.source.name})'); // Glock 43 (from mpn)

  // Calibers: free text and feed fields.
  print(findCalibers('Henry Big Boy .44 Mag/.44 Spl 20in')
      .map((c) => c.name)
      .toList()); // [.44 Magnum, .44 S&W Special]
  final c = normalizeCaliber('308 WIN (7.62X51 NATO)');
  print('${c?.name} -> ${c?.url}');
  // .308 Win -> https://gunsnprices.com/ammo/rifle-ammo/308-win

  // The numbers on their own.
  print(magazineCapacity('Springfield Hellcat Pro OSP 9mm 3.7in 15rd/17rd'));
  print(barrelLength('Mossberg 590 Persuader 12/20 BL/SY 3"')); // 20.0
  print(roundsPerBox('Winchester 308 150gr PowerMax Bonded 20rds')); // 20
  print(costPerRound(31.99, 20)); // 1.5995
}
