// Runs on every platform (VM, browsers, Node): `dart test -p chrome,vm`.
import 'package:gunsnprices/gunsnprices.dart';
import 'package:test/test.dart';

void main() {
  test('firearm', () {
    final info =
        parseTitle('Glock 19 Gen 5 MOS 9mm 4.02in 15rd Pistol PA195S203MOS');
    expect(info.kind, ProductKind.firearm);
    expect(info.model?.model, 'Glock 19 Gen 5 MOS');
    expect(info.caliber?.id, '9x19mmparabellum');
    expect(info.capacity, 15);
    expect(info.barrelLength, 4.02);
  });

  test('ammo', () {
    final info = parseTitle(
        'Federal American Eagle 5.56x45mm 55gr FMJ 1000 Rounds',
        price: 449.99);
    expect(info.kind, ProductKind.ammo);
    expect(info.caliber?.name, '5.56×45mm NATO');
    expect(info.rounds, 1000);
    expect(info.costPerRound, 0.45);
  });

  test('models, calibers and numbers', () {
    expect(identifyModel('Sig Sauer P365 XL 9mm 3.7" 12+1 Optic Ready')?.model,
        'Sig Sauer P365 XL');
    expect(
        identifyModel('GLOCK 9MM PISTOL 15RD', brand: 'Glock', mpn: 'UA4350201')
            ?.model,
        'Glock 43');
    expect(identifyModel('Glock 19 holster'), isNull);
    expect(
        findCalibers('Ruger GP100 .357 Mag / .38 Special 4.2in Revolver')
            .map((c) => c.id),
        ['357mag', '38swspecial']);
    expect(findCalibers('Beretta 686 O/U 12/28 BL/WD 3"').map((c) => c.id),
        ['12gauge']);
    expect(normalizeCaliber('12 GA')?.name, '12 Gauge');
    expect(magazineCapacity('Kimber CDS9 9mm 3.18in 13rd/15rd Black'), 15);
    expect(barrelLength('Colt Python 4 1/4" .357'), 4.25);
    expect(barrelLength('Mossberg 590 Persuader 12/20 BL/SY 3"'), 20);
    expect(roundsPerBox('Barnaul 7.62x39 123gr FMJ 20/25'), 20);
    expect(costPerRound(425, 800), 0.5312);
    expect(barrelLength('Barrett MRAD 26&quot; Barrel'), 26);
    expect(listBrands(), hasLength(50));
    expect(listCalibers().length, greaterThan(250));
  });
}
