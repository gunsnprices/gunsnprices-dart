@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:gunsnprices/gunsnprices.dart';
import 'package:test/test.dart';

void main() {
  group('identifyModel', () {
    final cases = [
      (
        'Glock 19 Gen 5 MOS 9mm 4.02in 15rd Pistol',
        null,
        null,
        'Glock 19 Gen 5 MOS'
      ),
      ('G19 Gen5 9mm 15rd FS', 'Glock', null, 'Glock 19 Gen 5'),
      ('Glock 43X 9mm 3.41in 10rd Black', null, null, 'Glock 43X'),
      ('GLOCK 9MM PISTOL 15RD', 'Glock', 'PA195S203', 'Glock 19 Gen 5'),
      (
        'Sig Sauer P365 XL 9mm 3.7in 12rd Pistol',
        null,
        null,
        'Sig Sauer P365 XL'
      ),
      ('Ruger GP100 .357 Mag 4.2in 6rd Revolver', null, null, 'Ruger GP100'),
    ];
    for (final (title, brand, mpn, model) in cases) {
      test(title, () {
        expect(identifyModel(title, brand: brand, mpn: mpn)?.model, model);
      });
    }

    test('rejects airguns, accessories and unknown titles', () {
      for (final t in [
        'Umarex Glock 19 CO2 BB Pistol .177',
        'Hornady 9mm 115gr FTX Critical Defense 25rd',
        'Glock 19 holster',
        'Sig P365 XL 12rd Magazine 9mm',
        'Magpul PMAG for Glock 19',
        '',
      ]) {
        expect(identifyModel(t), isNull, reason: t);
      }
      expect(identifyModel(null), isNull);
    });

    test('included accessories keep the gun', () {
      expect(identifyModel('Glock 19 Gen 5 9mm 15rd w/ 3 magazines')?.model,
          'Glock 19 Gen 5');
      expect(identifyModel('Daniel Defense DDM4 V7 (No Magazine)'), isNotNull);
    });

    test('decodes Glock part numbers', () {
      final m = identifyModel('GLOCK 9MM PISTOL 15RD',
          brand: 'Glock', mpn: 'PA195S203');
      expect(m?.source, ModelSource.mpn);
      expect(m?.family, 'Glock 19');
      final g43 = identifyModel('GLOCK 9MM PISTOL 15RD',
          brand: 'Glock', mpn: 'UA4350201');
      expect(g43?.toJson(), {
        'brand': 'Glock',
        'family': 'Glock 43',
        'model': 'Glock 43',
        'generation': '',
        'configs': <String>[],
        'features': <String>[],
        'source': 'mpn',
      });
    });
  });

  group('findCalibers', () {
    final cases = [
      (
        'Ruger GP100 .357 Mag / .38 Special 4.2in Revolver',
        ['.357 Mag', '.38 S&W Special']
      ),
      (
        'Federal American Eagle 9mm Luger 115gr FMJ 50rd',
        ['9×19mm Parabellum']
      ),
      ('Hornady 6.5 Creedmoor 143gr ELD-X', ['6.5mm Creedmoor']),
      ('PSA AR-15 300 Blackout 16in Rifle', ['.300 AAC Blackout']),
      ('Kent 12G Fasteel 3in BBB', ['12 Gauge']),
      ('Beretta 686 O/U 12/28 BL/WD 3"', ['12 Gauge']),
      ('Winchester 308 150gr PowerMax Bonded 20rds', ['.308 Win']),
      ('Remington 7mm RM 26" Bolt Rifle', ['7mm Remington Magnum']),
      ('Henry Big Boy .44 Mag/.44 Spl 20in', ['.44 Magnum', '.44 S&W Special']),
      ('Model 1911 Range Officer Parkerized', <String>[]),
      ('Umarex 12g CO2 Cartridges 15 pack', <String>[]),
      ('Hornady 9&#215;19mm 115gr', ['9×19mm Parabellum']),
    ];
    for (final (text, names) in cases) {
      test(text, () {
        expect(findCalibers(text).map((c) => c.name), names);
      });
    }
    test('findCaliber', () {
      expect(findCaliber('S&W M&P 2.0 .40 S&W')?.id, '40sw');
      expect(findCaliber('no caliber'), isNull);
    });
  });

  test('normalizeCaliber', () {
    expect(normalizeCaliber('9mm Luger')?.id, '9x19mmparabellum');
    expect(normalizeCaliber('5.56 NATO')?.id, '5-56x45mmnato');
    expect(normalizeCaliber('12 GA')?.name, '12 Gauge');
    final c = normalizeCaliber('308 WIN (7.62X51 NATO)')!;
    expect(c.toJson(), {
      'id': '308win',
      'name': '.308 Win',
      'type': 'rifle',
      'url': 'https://gunsnprices.com/ammo/rifle-ammo/308-win',
    });
    expect(c.type, CaliberType.rifle);
    expect(normalizeCaliber('nothing here'), isNull);
  });

  test('lists', () {
    expect(listBrands(), hasLength(50));
    expect(listBrands(), contains('Glock'));
    final cals = listCalibers();
    expect(cals.length, greaterThan(250));
    expect(cals.map((c) => c.id).toSet(), hasLength(cals.length));
  });

  group('magazineCapacity', () {
    for (final (title, cap) in [
      ('Glock 19 Gen5 9mm 4.02in 15+1', 15),
      ('Kimber CDS9 9mm 3.18in 13rd/15rd Black', 15),
      ('Savage 110 Scout 450 Bushmaster 4 Round Bolt Action', 4),
      ('Ruger 10/22 Carbine 22LR', null),
    ]) {
      test(title, () => expect(magazineCapacity(title), cap));
    }
  });

  group('barrelLength', () {
    for (final (title, inches) in [
      ('Ruger GP100 .357 Mag 4.2in Revolver', 4.2),
      ('Beretta A300 Ultima 12 GA 3" Chamber 28" Barrel', 28.0),
      ('Mossberg 590 Persuader 12/20 BL/SY 3"', 20.0),
      ('Colt Python 4 1/4" .357', 4.25),
      ('Ruger 10/22 SBR 22LR 8in 15rd', 8.0),
      ('Bergara B-14 24" 1:8" twist', 24.0),
      ('Glock 19 Gen5 9mm', null),
    ]) {
      test(title, () => expect(barrelLength(title), inches));
    }
  });

  group('roundsPerBox', () {
    for (final (title, n) in [
      ('Federal American Eagle 9mm 115gr FMJ, 50/Box', 50),
      ('Prvi Partizan 5.56x45mm M193 55gr 1,000 Rounds', 1000),
      ('Lapua 8x57 IRS 180gr Naturalis Box of 20', 20),
      ('Barnaul 7.62x39 123gr FMJ 20/25', 20),
      ('Winchester Super-X .30-30 Win 150gr', null),
      ('Junk 123,456,789,012,345,678,901 Rounds', null),
    ]) {
      test(title, () => expect(roundsPerBox(title), n));
    }
  });

  test('costPerRound', () {
    expect(costPerRound(18.99, 50), 0.3798);
    expect(costPerRound(425, 800), 0.5312); // exact tie goes to even
    expect(costPerRound(0, 50), isNull);
    expect(costPerRound(10, null), isNull);
  });

  test('looksLikeAmmo', () {
    expect(
        looksLikeAmmo('Hornady 9mm 115gr FTX Critical Defense 25rd'), isTrue);
    expect(looksLikeAmmo('Glock 19 Gen 5 9mm Pistol'), isFalse);
  });

  test('parseTitle firearm', () {
    final info = parseTitle('Glock 19 Gen5 MOS 9mm 4.02in 15+1 Black');
    expect(info.kind, ProductKind.firearm);
    expect(info.brand, 'Glock');
    expect(info.model?.model, 'Glock 19 Gen 5 MOS');
    expect(info.caliber?.name, '9×19mm Parabellum');
    expect([info.capacity, info.barrelLength, info.rounds], [15, 4.02, null]);
  });

  test('parseTitle ammo', () {
    final info = parseTitle(
        'Federal American Eagle 9mm Luger 115gr FMJ, 50/Box',
        price: 18.99);
    expect(info.kind, ProductKind.ammo);
    expect(info.model, isNull);
    expect([info.rounds, info.costPerRound, info.caliber?.id],
        [50, 0.3798, '9x19mmparabellum']);
    final json = jsonDecode(jsonEncode(info)) as Map<String, dynamic>;
    expect(json['kind'], 'ammo');
    expect(json['cost_per_round'], 0.3798);
  });

  test('parseTitle with kind and brand', () {
    final info =
        parseTitle('Some 9mm thing', kind: ProductKind.ammo, brand: 'Acme');
    expect(info.kind, ProductKind.ammo);
    expect(info.brand, 'Acme');
  });

  test('HTML entities like Python html.unescape', () {
    expect(barrelLength('Barrett MRAD 26&quot; Barrel'), 26.0);
    expect(magazineCapacity('Barrett 19056 MRAD 26&quot; 10&#x2B;1'), 10);
    expect(findCalibers('9mm &#99999999999999999999; &bogus; &ampx'),
        hasLength(1));
  });

  test('cli', () async {
    final r = await Process.run(Platform.resolvedExecutable,
        ['run', 'bin/gunsnprices.dart', 'Glock', '19', 'Gen', '5', '9mm']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final out = jsonDecode(r.stdout as String) as Map<String, dynamic>;
    expect((out['model'] as Map<String, dynamic>)['model'], 'Glock 19 Gen 5');
  });
}
