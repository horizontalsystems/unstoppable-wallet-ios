# Platform divergences

> This page records where the iOS and Android wallets differ. The two apps aim at identical behaviour, except where a platform makes that impossible or demands an absurd approach. A divergence is recorded where it is met and is not changed by the work that finds it. Each entry gives the element and a one-line reason.

## Divergences

- **Search field kind.** Android's `search_bar` tags a custom floating row that activates its text field when tapped, and the flows tap it, then type. iOS uses the system `searchable` field, which carries no identifier of ours, so `search_bar` is not declared on iOS. An identifier set after `.searchable` lands on the wrapped list, and a tap by id hits a row. The iOS flow selects the field by its prompt text or field type.
- **Intro timing.** The iOS intro covers the start button with an animated logo for a moment. Android's intro has no overlay, and its flow taps `intro_next` with no wait.
- **Terms.** Android's `MonetizationDisclosure` term has no counterpart in iOS's `TermsConfiguration.current`, though its text matches iOS's `commission` term of an earlier configuration. It sits mid-list, so `terms_check_<index>` selects a different term on each platform from that position on.
- **Sheets where Android pushes.** iOS shows many screens as sheets where Android pushes them. Maestro's `back` and `pressKey: Back` do nothing on iOS. iOS leaves a pushed screen with the system back button, whose identifier `BackButton` is iOS's own, and leaves a sheet with its close or check icon, which carries no identifier of ours. So leaving a screen differs per platform, and the shared flows leave through one subflow.
- **Numeric keypad.** iOS's numeric keypads, the swap and send amounts, have no dismiss key, so `hideKeyboard` fails there, and the keypad covers the tab bar, so a `tab_*` tap lands on it and reports success. The system numeric pad carries no dismiss key and the screens add none.
- **Passcode error presence.** iOS always renders the error `Text`, empty when there is no error. Android renders its error element only while one exists. Maestro sees the empty element, with bounds and empty text, so a flow asserts the passcode error by its text, whether present or absent.
- **Launch clear of the keychain.** Android's data clear wipes everything the app has. On iOS the keychain is the app's to clear, and the app clears it on the first launch after a wipe, after the passcode has already been read. So that launch asks for an erased passcode, and the shared flows clear the keychain on iOS before a clean start.
- **Watch token list.** `WatchSelectView`'s `.coins` case carries no `watch_chain` tag, while Android tags each item with its blockchain uid. On iOS that uid is not unique across derivations.
- **Row tap against switch.** On Android a row tap toggles, both for `restore_chain_<uid>` and for `manage_coin_<coinCode>_<blockchainUid>`. On iOS only the switch toggles. The name sits on the switch, so selection by name is unaffected.
- **Enter-address error card.** Android shows `enter_address_error` for every invalid address. iOS shows its card only when a parser gives its own reason; for a plainly malformed address it reddens the border and disables the button, titled `Invalid Address`. The iOS flow waits on `enter_address_submit` disabled.
- **Waiting for sync in transactions.** Android shows `tx_waiting_sync` while the list is empty and syncing. iOS shows one empty placeholder, so `tx_waiting_sync` has no iOS element and `tx_empty` shows during sync.
- **Swap wallet-syncing error.** Android gives `swap_error` for `WalletSyncing` (`TokenBalanceService.validate`) when the adapter's balance is syncing while the wallet is not. iOS has no such branch, and no flow reaches it.
- **Surplus names on iOS.** iOS carries `confirm_network_fee` on cross pay and private send, on the EVM approve and revoke, the Tron approve, and the XRP trust-set and Stellar change-trust activations (all through a tagged data's `feeFields`), and `confirm_send` on every `RegularSendView`, where Android does not. iOS never lacks a name Android carries, and a surplus that would cost code to remove is recorded.
- **Auto-lock.** Android's `autolock_<raw>` tags the rows of a page that `security_autolock` pushes. iOS opens an option alert over the screen, and the names sit on the alert's rows.
- **Biometrics.** Android's `security_biometrics` tags a switch. iOS has a choice row of off, manually and on, so the name sits on that row.
- **Debug fail-swap row.** Android's `settings_debug_simulate_fail_swap` cycles the mode on each tap. iOS opens an alert for it. The name sits on the row.
- **Debug swap provider name.** Android has a "Show swap provider name" row that iOS does not, so `settings_debug_swap_provider_name` has no iOS element and is not declared.
- **File backup row.** Android's wallet page has a file-backup row, `account_local_backup`. The iOS wallet page offers iCloud backup rows and no file-backup row, so the name has no iOS element and is not declared.
- **Currency list.** Android lists `ARS` and no `RON`, and iOS lists `RON` and no `ARS`, so `currency_ARS` has no iOS element and `currency_RON` has no Android one.
- **Whitespace wallet name (an iOS defect).** iOS enables Save for a wallet name of spaces and saves it empty. Android trims the name before checking it.
- **E2E build identity.** Android's e2e build type takes `applicationIdSuffix = ".e2e"` and installs beside the dev build. iOS's E2E build shares Development's bundle id and replaces it, because a separate id would carry new extension ids, an app group and entitlements.
- **WalletConnect sign-only requests in the E2E build.** iOS's [broadcast guard](e2e-build.md) sits at the one send port, `SendViewModel.send()`, so in the E2E build it also stops the WalletConnect requests that only sign: `WCEvmSendHandler`'s sign case and the Stellar sign case. Android guards inside its send services (`checkBroadcastAllowed()` in `SendTransactionService*`), so a sign-only request passes. No flow drives a WalletConnect sign.

## Not divergences

The balance-row sync state is the same on both platforms. Both use one icon element whose name follows the state. iOS's `customSyncing` maps to `syncing`, and `stopped`, which Android lacks, maps to `synced`.

The passcode error is the same on both platforms. Android's `PinTopBlock.kt` shows `pin_error` or `pin_attempts_left` in one `when`, one at a time, as iOS does with the name as a parameter. Only the empty error text of the divergence above differs.

The landing tab, the backup quiz shape and the watch submit behave the same on both platforms, and only the label of the first watch button differs.

## Controls not yet named

These controls exist on both platforms, and Android has not named them: the wallet-name field on restore and watch, the advanced options on create and restore, the keyboard suggestions, paste and scan, and the pad's biometry and "random" options. iOS names one by the [convention](test-identifiers.md) when a flow first selects it, and the shared flow selecting it carries the name to Android, which declares it when it runs the flow.

## Changes to Android's flows

These are changes the shared flows make to Android's original flows that Android meets when it runs them.

- **Dust check amount parse.** Android's original reads the amount keeping only digits and dots, so in a comma-decimal region `0,00005` reads as `5` and the check passes on any balance; the shared flow reads the last `.` or `,` as the decimal mark.
