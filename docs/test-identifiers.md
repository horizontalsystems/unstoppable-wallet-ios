# Test identifiers

> This page states how the iOS app names the controls that Maestro flows select, and the protocol those names follow.

## The protocol

The Maestro flows live in appkb's root `flows/` on its branch `flows` and select controls by name. Both apps use the same names, so a flow written for one runs on the other.

- `TestTags` is a name's one declared home in each app. No app is the source of truth: a name belongs to whichever app declares it first, and both use the same string.
- A flow uses only declared names. A name a new flow needs is declared with the flow.
- A shared flow that selects `id: X` binds both apps to carry `X`. When an app runs it, a missing name fails there, and that app declares the same name.
- A name is renamed or removed only together with every flow that selects it, in the app's repository and in appkb.
- A check runs in each app's CI on each PR and by hand, and fails a PR that removes or renames a name a flow selects. A name a flow selects that no declaration has held yet is reported, not failed. It exists because an undeclared name in a conditional step, `when: visible` or `optional: true`, is skipped silently, where in a plain step it fails the run.

## Looking for a name

Before declaring a name, look in this order, and reuse what is found. A new name is declared only when none exists.

1. The shared flows, appkb's `flows/`. A name a flow selects is the contract, and an app that differs renames.
2. Android's `TestTags`, `walletkit/src/main/java/io/horizontalsystems/walletkit/uiv3/TestTags.kt` in `horizontalsystems/unstoppable-wallet-android`.
3. iOS's `TestTags`, `packages/WalletCore/Sources/WalletCore/UserInterface/TestTags.swift`.

One control has one name. If the two apps named a control differently and no flow selects either name, the older name wins.

## Which controls get a name

Every control the user interacts with, and every value a test checks, gets its name in the same change that writes it, not when a test first needs it. The controls are a SwiftUI `Button`, `Toggle`, `TextField` or `SecureField`, `Picker`, `NavigationLink`, anything with an `onTapGesture`, and a UIKit control in new code. A container that only passes callbacks down has no name of its own; the controls inside it do.

## Names

- A name has the form `<screen>_<element>` in snake_case, even where snake_case breaks iOS naming conventions. It carries a dynamic suffix only where a flow must pick one item of a list.
- iOS declares each name in its own `TestTags`: a constant is a `static let` in lowerCamelCase holding the string, and a name with a dynamic suffix is a `static func` taking the suffix.

## Applying a name

- A name sits on the control or value element itself, the one a user taps or a test reads, and not on a container around it. A name that lands on no element is not declared.
- Identifiers are always on. No build flag gates them.
- An existing UIKit control is tagged only where that needs no rework.

## Names one platform has

- A control only iOS has takes a name by the same convention, and the case is recorded in the [platform divergences](platform-divergences.md).
- A platform's own identifier is allowed in a flow only inside that platform's `when: platform` branch. `BackButton`, the system's identifier on the navigation back button, is iOS's own.
