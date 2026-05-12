# Restore Mnemonic AutoFill Suppression

## Goal

Prevent iOS Password AutoFill / password suggestion UI from appearing on the
Restore Account mnemonic field when the optional passphrase field is shown.

## Assumptions

- The issue is in the Restore Account recovery phrase flow, not cloud backup
  restore.
- The mnemonic input should never be treated as a password, username, or saved
  credential field.
- The BIP-39 passphrase in this screen is a wallet seed salt, not an app login
  password, so password-manager suggestions are not desired there either.
- The existing mnemonic suggestions row should keep working.

## Scope

- Review and adjust text input traits for Restore Account mnemonic and
  passphrase fields.
- Prefer the smallest localized changes that prevent password suggestions while
  preserving current validation, focus, secure reveal, paste, QR scan, and
  mnemonic word suggestion behavior.

## Affected Areas

- `Unstoppable/Unstoppable/Modules/RestoreAccount/RestoreMnemonic/RestoreMnemonicView.swift`
- `Unstoppable/Unstoppable/Modules/RestoreAccount/RestoreMnemonic/MnemonicInputCellWrapper.swift`
- `Unstoppable/Unstoppable/UserInterface/Cells/TextInputCell.swift`
- `Unstoppable/Unstoppable/UserInterface/SwiftUI/InputTextView.swift`

## Proposed Approach

- Mark the mnemonic `UITextView` with an explicit non-password semantic content
  type, most likely `UITextContentType.oneTimeCode`, instead of relying on an
  empty raw content type.
- Ensure the Restore Account passphrase input uses the same non-password
  semantic in both hidden `SecureField` and visible `TextField` states.
- Keep the fix scoped to Restore Account if changing shared input components
  would affect unrelated screens.
- Optionally disable inline predictions on UIKit text inputs where the API is
  available.

## Acceptance Criteria

- Opening Restore Account and enabling advanced options does not show password
  suggestions on the mnemonic field.
- Focusing mnemonic after passphrase appears still shows only the app's mnemonic
  word suggestions row.
- Focusing passphrase does not trigger saved-password or strong-password
  suggestions.
- Toggling passphrase visibility does not reintroduce password suggestions.
- Existing typing, paste, QR scan, validation, and Next button behavior are
  unchanged.

## Verification Plan

- Build the iOS target to catch Swift compile errors.
- Manual QA on a real iOS device with iCloud Keychain enabled:
  - Restore Account -> Recovery Phrase.
  - Type mnemonic words.
  - Enable Advanced Options.
  - Focus mnemonic and passphrase fields in both passphrase visibility states.
  - Confirm password suggestions do not appear on mnemonic.
- If a simulator is used, treat AutoFill verification as partial because
  password suggestion behavior differs from real devices.

## Open Questions

- Should cloud backup restore passphrase fields keep their current password
  suggestion suppression behavior, or should they share the same explicit API
  if `InputTextView` is changed globally?
- Which minimum iOS version is required for adding `inlinePredictionType = .no`
  behind an availability check?
