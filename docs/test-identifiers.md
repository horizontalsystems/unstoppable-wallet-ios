# Test identifiers

> This page states how the iOS app names the controls that Maestro flows select, and the protocol those names follow.

## The protocol

The Maestro flows live in appkb's root `flows/` on its branch `main` and select controls by name. Both apps use the same names, so a flow written for one runs on the other.

The test lab writes the flows and repairs them when a change breaks them. A developer, and the developer's agent, declares a control's name in code with the change and writes or edits no flow.

- `TestTags` is a name's one declared home in each app. No app is the source of truth: a name belongs to whichever app declares it first, and both use the same string.
- A name is declared with the change that writes its control, never with a flow.
- A shared flow that selects `id: X` binds both apps to carry `X`. When an app runs it, a missing name fails there, and that app declares the same name.
- A name a flow selects is kept, and a control that replaces it takes the same name. When a change removes a control whose name a flow selects, the test lab updates the flows.
- A check runs in the app's CI on each pull request and by hand. It fails a pull request only when a name that the pull request's base declares, and that a flow selects, is missing at the pull request's head. Every other name a flow selects that the app does not declare is reported and does not fail: a name the code has not reached yet, and an identifier that is not the app's own. It reads only the flows that drive the wallet itself, a flow whose `appId` is another app is not read, and it skips the other platform's `when: platform` branches. It exists because an undeclared name in a conditional step, `when: visible` or `optional: true`, is skipped silently, where in a plain step it fails the run.

## Looking for a name

Before declaring a name, look in this order, and reuse what is found. A new name is declared only when none exists.

1. The shared flows, appkb's root `flows/` on `main`. A name a flow selects is the contract, and an app that differs renames.
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
- A container that carries a name becomes an accessibility element. `.accessibilityElement(children: .contain)` goes on it only where a flow reads a part inside it, never everywhere, and the E2E flag does not gate it. `.combine` serves the other case, a composite a flow addresses as one element.
- An existing UIKit control is tagged only where that needs no rework.

## Names one platform has

- A control only iOS has takes a name by the same convention, and the case is recorded in the [platform divergences](https://github.com/horizontalsystems/appkb/blob/main/flows/platform-divergences.md).
- A platform's own identifier is allowed in a flow only inside that platform's `when: platform` branch. `BackButton`, the system's identifier on the navigation back button, is iOS's own.
