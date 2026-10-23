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

    static let backupReveal = "backup_reveal"
    static func backupWord(_ number: Int) -> String { "backup_word_\(number)" }
    static let backupVerify = "backup_verify"

    static func quizPosition(_ index: Int) -> String { "quiz_position_\(index)" }
    static func quizOption(_ word: String) -> String { "quiz_option_\(word)" }

    static func pinKey(_ digit: Int) -> String { "pin_key_\(digit)" }
    static let pinKeyDelete = "pin_key_delete"
    static let pinTitle = "pin_title"
    static let pinError = "pin_error"
    static let pinAttemptsLeft = "pin_attempts_left"

    static func tab(_ name: String) -> String { "tab_\(name.lowercased())" }

    static let balanceTotal = "balance_total"

    static let balanceScan = "balance_scan"
    static let balanceReceive = "balance_receive"
    static let balanceSend = "balance_send"
    static let balanceSwap = "balance_swap"

    static let balanceTransactions = "balance_transactions"
    static let balanceManageAccounts = "balance_manage_accounts"
    static let balanceManageCoins = "balance_manage_coins"
    static let balanceSyncIndicator = "balance_sync_indicator"

    static func balanceItem(_ coinCode: String) -> String { "balance_item_\(coinCode)" }
    static func balanceItemAmount(_ coinCode: String) -> String { "balance_item_\(coinCode)_amount" }
    static func balanceItemSync(_ coinCode: String, _ state: String) -> String { "balance_item_\(coinCode)_\(state)" }

    static let tokenBalance = "token_balance"
    static let tokenChart = "token_chart"
    static let tokenReceive = "token_receive"
    static let tokenSend = "token_send"
    static let tokenSwap = "token_swap"
    static let tokenTronViewAddress = "token_tron_view_address"

    static let receiveAddress = "receive_address"
    static let receiveNetwork = "receive_network"
    static let receiveFormat = "receive_format"
    static let receiveAddressType = "receive_address_type"
    static let receiveSetAmount = "receive_set_amount"
    static let receiveShare = "receive_share"
    static let receiveCopy = "receive_copy"

    static func manageCoin(_ coinCode: String, _ blockchainUid: String) -> String { "manage_coin_\(coinCode)_\(blockchainUid)" }

    static let sendAmountInput = "send_amount_input"
    static let sendRecipientRow = "send_recipient_row"
    static let sendNext = "send_next"
    static let sendAction = "send_action"

    static let enterAddressInput = "enter_address_input"
    static let enterAddressSubmit = "enter_address_submit"
    static let enterAddressError = "enter_address_error"

    static let confirmAmount = "confirm_amount"
    static let confirmRecipient = "confirm_recipient"
    static let confirmNetworkFee = "confirm_network_fee"
    static let confirmSend = "confirm_send"

    static let txEmpty = "tx_empty"
    static let txFilter = "tx_filter"
    static func txItem(_ uid: String) -> String { "tx_item_\(uid.prefix(8))" }
    static func txInfoStatus(_ state: String) -> String { "tx_info_status_\(state)" }
    static func txInfoHash(_ hash: String) -> String { "tx_info_hash_\(hash.prefix(8))" }
}
