# Crypto Wallet Review Guidelines

Consumed by automated code review (CodeRabbit) and by human reviewers.

## 1. Secret material

**Secret material** = mnemonic phrases, BIP-39 seeds, private keys,
extended private keys, signing keys, passphrases, PINs.

- MUST NOT appear in logs, analytics, crash reports, telemetry.
- MUST NOT be written to clipboard automatically or from background
  business logic.
- Clipboard copy is allowed only as an explicit user action from a
  sensitive-data screen, ideally with a confirmation step and routed
  through the app's centralized clipboard helper.
- MUST NOT be persisted in `UserDefaults`, plist, or plain files.
- Acceptable storage only: Keychain (`SecItemAdd`) with
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` or stricter.

## 2. Randomness

Cryptographic randomness MUST use:
- `SecRandomCopyBytes` or `CryptoKit`.

`arc4random`, `Int.random`, and `Double.random` are prohibited in any code
path deriving nonces, salts, IVs, or private keys.

## 3. iOS architecture (project conventions)

- Modal presentation through `Coordinator.shared` only. No direct
  `.sheet` / `.fullScreenCover` / UIKit `present` in SwiftUI views.
- Mutations of `@Published` from `Task { ... }` go through
  `@MainActor` methods.
- Push navigation via `NavigationPath` + `navigationDestination(for:)`.
- `.xcodeproj/project.pbxproj`, `.xcconfig`, `.entitlements`,
  `Info.plist` — edited only through Xcode, not by hand.
