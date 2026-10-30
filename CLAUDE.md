# Unstoppable Wallet iOS

## Purpose

Unstoppable Wallet iOS is the iOS app of Unstoppable, a non-custodial multi-blockchain wallet by Horizontal Systems: storage and transfer of crypto, on-chain and provider swaps, market analytics, and WalletConnect. It is written in Swift, with SwiftUI and some UIKit still in place. Its Android counterpart is the same app on the other platform; the two aim at identical behaviour.

## Commands

- Open `Wallet.xcworkspace`. It holds the app project `Unstoppable/Unstoppable.xcodeproj` and the local Swift package `packages/WalletCore`, where nearly all the code lives.
- Before the first build, create `Unstoppable/Unstoppable/Configuration/Config.xcconfig` from `Config.template.xcconfig` in the same folder. The file holds API keys and is git-ignored.
- Schemes: `Development` (the `Debug-Dev` and `Release-Dev` configurations, the `.dev` bundle ids), `Production` (the `Debug-Prod` and `Release-Prod` configurations) and `E2E` (the `Debug-E2E` configuration, described in [`docs/e2e-build.md`](docs/e2e-build.md)). The unit-test target is `AppTests`, in `Unstoppable/Tests`.
- fastlane, through Bundler (`Gemfile`, Ruby from `.ruby-version`): the lanes are `dev` (builds `Development`, ad hoc, uploads to Firebase), `release` (builds `Production`, uploads to TestFlight), `match_readonly` and `match_generate` (provisioning profiles). Run one as `bundle exec fastlane <lane>`. GitHub Actions runs `dev` on pushes to `develop` and `release` on pushes to `master`; the release steps are in [`RELEASE.md`](RELEASE.md).

## Screens and tests

The Maestro flows live in appkb's root `flows/` on its branch `flows` and select controls by the names in `TestTags`. A new or changed control gets its `TestTags` name in the same change, per [`docs/test-identifiers.md`](docs/test-identifiers.md).

## Documentation

| Doc | What it covers |
|---|---|
| [`docs/test-identifiers.md`](docs/test-identifiers.md) | The names protocol, and how the app names the controls Maestro flows select: which controls get a name, its form, and where it sits |
| [`docs/e2e-build.md`](docs/e2e-build.md) | What the E2E build is: its configuration and flag, what the flag changes, the command that builds it for a simulator, and the conditions of a run |
| [`docs/platform-divergences.md`](docs/platform-divergences.md) | Where the iOS and Android wallets differ, element by element, with the reason |
| [`docs/CRYPTO_GUIDELINES.md`](docs/CRYPTO_GUIDELINES.md) | Review guidelines for a crypto wallet: secret material, randomness, and the iOS architecture conventions |
| [`appkb`](https://github.com/horizontalsystems/appkb) | The foundation of existing behaviour: what both apps do now, generated per release from the code. A task that changes behaviour says so, and its spec is then the foundation. Looked up as set out below the table |

appkb is looked up in the folder of a version, `kb-<version>`. A screen's behaviour is `docs/features/<platform>/<screen type name>.md`, found by the screen's type in the code. A task's steps are `docs/how-to/<task>.md`, and the text of an error is `docs/errors/<platform>/<string key>.md`. `xplatform.md` pairs the screens of the two platforms, and `docs/records.jsonl` holds the same records in machine form.
