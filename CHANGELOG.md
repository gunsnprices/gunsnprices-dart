## 0.1.0 (2026-11-10)

First release. Dart port of the [gunsnprices](https://pypi.org/project/gunsnprices/)
Python package 0.1.2, with identical results on the 1,150 recorded store titles
of its test suite (on the Dart VM and compiled to JavaScript) and on all 63,755
titles of the GunsNPrices catalog.

- `parseTitle()`: firearm or ammo, brand, model, calibers, magazine capacity,
  barrel length, rounds per box, cost per round.
- `identifyModel()`: 50 brands, the same model dictionaries that
  [GunsNPrices](https://gunsnprices.com) uses on its site; decodes Glock part
  numbers.
- `findCalibers()` / `normalizeCaliber()` / `listCalibers()`: 293 calibers
  with retailer spellings.
- `magazineCapacity()`, `barrelLength()`, `roundsPerBox()`, `costPerRound()`,
  `looksLikeAmmo()`.
- Command line: `dart pub global activate gunsnprices`, then
  `gunsnprices "title"`.
- Pure Dart, no dependencies; the data is compiled in, so it works in Flutter,
  on the web and on the server.
