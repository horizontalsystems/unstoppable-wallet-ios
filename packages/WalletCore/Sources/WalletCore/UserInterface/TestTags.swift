// Identifiers the Maestro flows select by. The names are Android's `TestTags` names taken
// verbatim, in snake_case on purpose. Renaming or removing one breaks the flows that select by it.
enum TestTags {
    static let introNext = "intro_next"

    static let onboardingNewWallet = "onboarding_new_wallet"
    static let onboardingExistingWallet = "onboarding_existing_wallet"
    static let onboardingWatchWallet = "onboarding_watch_wallet"

    static func termsCheck(_ index: Int) -> String { "terms_check_\(index)" }
    static let termsNext = "terms_next"

    static let createTypeStandard = "create_type_standard"
    static let createTypePasskey = "create_type_passkey"

    static let createNameInput = "create_name_input"
    static let createSubmit = "create_submit"

    static let importRecoveryPhrase = "import_recovery_phrase"
    static let importPrivateKey = "import_private_key"
    static let importPasskey = "import_passkey"
    static let importBackupFile = "import_backup_file"

    static let restorePhraseInput = "restore_phrase_input"
    static let restoreNext = "restore_next"
    static let restoreError = "restore_error"

    static let selectorDone = "selector_done"
    static func selectorSwitch(_ index: Int) -> String { "selector_switch_\(index)" }

    static func restoreChain(_ blockchainUid: String) -> String { "restore_chain_\(blockchainUid)" }
    static let restoreSubmit = "restore_submit"

    static let watchInput = "watch_input"
    static let watchSubmit = "watch_submit"

    static func watchChain(_ blockchainUid: String) -> String { "watch_chain_\(blockchainUid)" }
    static let watchChainsDone = "watch_chains_done"
}
