// gunsnprices "Glock 19 Gen 5 9mm 15rd"   -> parsed title as JSON
// cat titles.txt | gunsnprices            -> JSON Lines, one per input line
import 'dart:convert';
import 'dart:io';

import 'package:gunsnprices/gunsnprices.dart';

const _usage = '''
usage: gunsnprices [--brand B] [--mpn M] [--price P] [--kind firearm|ammo] ["title"]

Parses firearm and ammunition product titles and prints JSON.
Reads titles from stdin, one per line (JSON Lines out), when no title is given.''';

Future<void> main(List<String> args) async {
  String? brand;
  String? mpn;
  num? price;
  ProductKind? kind;
  final words = <String>[];
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    String next() {
      if (i + 1 >= args.length) _fail('$a needs a value');
      return args[++i];
    }

    switch (a) {
      case '--brand':
        brand = next();
      case '--mpn':
        mpn = next();
      case '--price':
        final v = next();
        price = num.tryParse(v) ?? _fail('--price: not a number: $v');
      case '--kind':
        final v = next();
        kind = ProductKind.values.where((k) => k.name == v).firstOrNull ??
            _fail('--kind must be firearm or ammo');
      case '--version':
        stdout.writeln('gunsnprices $packageVersion');
        return;
      case '-h' || '--help':
        stdout.writeln(_usage);
        return;
      default:
        words.add(a);
    }
  }
  ProductInfo parse(String t) =>
      parseTitle(t, brand: brand, mpn: mpn, price: price, kind: kind);
  if (words.isNotEmpty) {
    stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(parse(words.join(' '))));
    return;
  }
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final t = line.trim();
    if (t.isNotEmpty) stdout.writeln(jsonEncode(parse(t)));
  }
}

Never _fail(String message) {
  stderr
    ..writeln('gunsnprices: $message')
    ..writeln(_usage);
  exit(64);
}
