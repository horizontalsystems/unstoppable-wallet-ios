# Test identifiers

> This page states how the iOS app names the controls that UI tests select, and the protocol those names follow.

## The protocol

UI tests select controls by name, and both apps use the same names. A developer, and the developer's agent, declares a control's name in code with the change that writes the control, following this protocol.

- `TestTags` is a name's one declared home in each app. No app is the source of truth: a name belongs to whichever app declares it first, and both use the same string.
- A name is declared with the change that writes its control, never later.
- A declared name is kept: a control that replaces another takes its name.

## Looking for a name

Before declaring a name, look in both apps' `TestTags` and reuse what is found. A new name is declared only when none exists.

- iOS's `TestTags`: `packages/WalletCore/Sources/WalletCore/UserInterface/TestTags.swift`. A chain's names are declared in an `extension TestTags` inside that chain's folder (`Chains/<Chain>/`), with unchanged strings, so look there too before declaring a name.
- Android's `TestTags`: `walletkit/src/main/java/io/horizontalsystems/walletkit/uiv3/TestTags.kt` in `horizontalsystems/unstoppable-wallet-android`, read from GitHub with `gh api -H 'Accept: application/vnd.github.raw+json' 'repos/horizontalsystems/unstoppable-wallet-android/contents/<path>'`, which prints the file itself. The default branch is always read first; when the counterpart work sits on a branch not merged yet, that branch is read too, with `?ref=<branch>` inside the quotes. It is never read from a local checkout, which may be stale.

One control has one name. Where the two apps named a control differently, the older name wins.

## Which controls get a name

Every control the user interacts with, and every value a test checks, gets its name in the same change that writes it, not when a test first needs it. The controls are a SwiftUI `Button`, `Toggle`, `TextField` or `SecureField`, `Picker`, `NavigationLink`, anything with an `onTapGesture`, and a UIKit control in new code. A container that only passes callbacks down has no name of its own; the controls inside it do.

## Names

- A name has the form `<screen>_<element>` in snake_case, even where snake_case breaks iOS naming conventions. It carries a dynamic suffix only where a test must pick one item of a list.
- iOS declares each name in its own `TestTags`: a constant is a `static let` in lowerCamelCase holding the string, and a name with a dynamic suffix is a `static func` taking the suffix.

## Applying a name

- A name sits on the control or value element itself, the one a user taps or a test reads, and not on a container around it. A name that lands on no element is not declared.
- Identifiers are always on. No build flag gates them.
- A container that carries a name becomes an accessibility element. `.accessibilityElement(children: .contain)` goes on it only where a test reads a part inside it, never everywhere, and the E2E flag does not gate it. `.combine` serves the other case, a composite a test addresses as one element.
- An existing UIKit control is tagged only where that needs no rework.

## Names one platform has

A control only iOS has takes a name by the same convention; nothing more is asked of the developer.
