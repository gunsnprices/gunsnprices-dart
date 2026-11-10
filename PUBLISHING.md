# Publishing to pub.dev

Package: `gunsnprices` — https://pub.dev/packages/gunsnprices (the name was free on 2026-11-10:
`https://pub.dev/api/packages/gunsnprices` returned 404).

After publishing:

- package page: https://pub.dev/packages/gunsnprices (sidebar links: Homepage → https://gunsnprices.com, Repository,
  View/report issues, API reference)
- API docs (built by pub.dev from the dartdoc comments): https://pub.dev/documentation/gunsnprices/latest/
- score: https://pub.dev/packages/gunsnprices/score

Publishing is permanent: a version can't be deleted or overwritten. Within 7 days it can be *retracted*; a package can
later be marked *discontinued*, but it stays on pub.dev.

## 1. Account

pub.dev has no separate accounts: you sign in with a **Google account** (any Gmail or Google Workspace address). The
account that publishes first becomes the uploader of the package. Use an account the project keeps long term (for
example the one that owns app@gunsnprices.com, if it is a Google account).

## 2. Verified publisher (recommended, before the first publish)

A verified publisher shows "✓ gunsnprices.com" instead of a personal e-mail on the package page and links to the
domain. It needs proof that you control the DNS of gunsnprices.com:

1. Sign in at https://pub.dev with the Google account, open https://pub.dev/create-publisher and enter
   `gunsnprices.com`.
2. pub.dev sends you to Google Search Console to verify the domain. Choose the **Domain** property type; Search Console
   shows a TXT record like `google-site-verification=AbC123...`.
3. Add that TXT record at the root (`@`) of the gunsnprices.com DNS zone, wherever the zone is hosted, and keep it
   there (removing it later revokes the verification).
4. Wait until `dig +short TXT gunsnprices.com` shows the record, click **Verify** in Search Console, then go back to
   pub.dev and finish creating the publisher.
5. On the publisher's admin page set the contact e-mail (for example app@gunsnprices.com).

After the first publish (step 3), open https://pub.dev/packages/gunsnprices/admin, choose **Transfer to publisher**
and pick `gunsnprices.com`.

## 3. Publish

Requires the Dart SDK 3.5 or newer and a clean checkout of `main` with the version in `pubspec.yaml` and
`CHANGELOG.md` already bumped.

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart pub publish --dry-run     # must report 0 warnings
dart pub publish               # opens a browser for Google sign-in the first time, then asks for "y"
git tag v0.1.0 && git push origin v0.1.0
```

Optional check of the pub points before publishing (the same tool pub.dev runs):

```bash
dart pub global activate pana
pana .                          # 160/160 on 2026-11-10 (it warned only that the GitHub repo did not exist yet)
```

The GitHub repository `gunsnprices/gunsnprices-dart` should exist and be public before publishing: pub.dev links to
it and checks that the `repository` and `issue_tracker` URLs in `pubspec.yaml` are reachable.

## 4. Later releases from GitHub Actions (optional)

After the first manual publish, pub.dev can accept releases from GitHub Actions without stored secrets (OIDC):

1. https://pub.dev/packages/gunsnprices/admin → **Automated publishing** → enable *Publishing from GitHub Actions*,
   repository `gunsnprices/gunsnprices-dart`, tag pattern `v{{version}}`.
2. Add `.github/workflows/publish.yml`:

   ```yaml
   name: Publish to pub.dev
   on:
     push:
       tags: ['v[0-9]+.[0-9]+.[0-9]+*']
   jobs:
     publish:
       permissions:
         id-token: write
       uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
   ```

3. Release by pushing a tag: `git tag v0.1.1 && git push origin v0.1.1`.

## Updating the data

The model dictionaries and caliber list come from the Python package (`src/gunsnprices/data/*.json`). Copy the new
JSON files to `tool/data/`, then:

```bash
dart run tool/generate_data.dart && dart format lib
dart test                       # golden.jsonl must also be refreshed from the Python package
```
