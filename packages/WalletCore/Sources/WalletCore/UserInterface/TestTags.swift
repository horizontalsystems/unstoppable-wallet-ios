/// Identifiers the Maestro flows select by. The names are shared with the Android app's `TestTags`:
/// the same strings, in snake_case on purpose. Renaming or removing one breaks the flows that select by it.
/// The flows live in appkb. The rules for naming and adding a control are in `docs/test-identifiers.md`.
enum TestTags {
    static let introCreateWallet = "intro_create_wallet"
    static let introAddExistingWallet = "intro_add_existing_wallet"
    static let introAgreement = "intro_agreement"

    static let sheetClose = "sheet_close"

    static let onboardingNewWallet = "onboarding_new_wallet"
    static let onboardingExistingWallet = "onboarding_existing_wallet"
    static let onboardingWatchWallet = "onboarding_watch_wallet"

    static func termsCheck(_ index: Int) -> String {
        "terms_check_\(index)"
    }

    static let termsNext = "terms_next"

    static let createTypeStandard = "create_type_standard"
    static let createTypePasskey = "create_type_passkey"

    static let createNameInput = "create_name_input"
    static let createNameRandom = "create_name_random"
    static let createPassphraseInput = "create_passphrase_input"
    static let createPassphraseEye = "create_passphrase_eye"
    static let createPassphraseConfirmInput = "create_passphrase_confirm_input"
    static let createPassphraseConfirmEye = "create_passphrase_confirm_eye"
    static let createSubmit = "create_submit"

    static let importRecoveryPhrase = "import_recovery_phrase"
    static let importPrivateKey = "import_private_key"
    static let importPasskey = "import_passkey"
    static let importBackupFile = "import_backup_file"

    static let restorePhraseInput = "restore_phrase_input"
    static let restoreNext = "restore_next"
    static let restoreError = "restore_error"
    static let restoreNameInput = "restore_name_input"
    static let restoreNameRandom = "restore_name_random"
    static let restorePhraseScan = "restore_phrase_scan"
    static let restorePhrasePaste = "restore_phrase_paste"
    static let restorePhraseClear = "restore_phrase_clear"
    static let restorePassphraseInput = "restore_passphrase_input"
    static let restorePassphraseEye = "restore_passphrase_eye"
    static let restoreKeyNameInput = "restore_key_name_input"
    static let restoreKeyNameRandom = "restore_key_name_random"
    static let restoreKeyInput = "restore_key_input"
    static let restoreKeyScan = "restore_key_scan"
    static let restoreKeyPaste = "restore_key_paste"
    static let restoreKeyClear = "restore_key_clear"
    static let restoreFilePasswordInput = "restore_file_password_input"
    static let restoreFilePasswordEye = "restore_file_password_eye"

    static let selectorDone = "selector_done"
    static func selectorSwitch(_ index: Int) -> String {
        "selector_switch_\(index)"
    }

    static func restoreChain(_ blockchainUid: String) -> String {
        "restore_chain_\(blockchainUid)"
    }

    static let restoreSubmit = "restore_submit"

    static let watchInput = "watch_input"
    static let watchSubmit = "watch_submit"
    static let watchNameInput = "watch_name_input"
    static let watchNameRandom = "watch_name_random"
    static let watchScan = "watch_scan"
    static let watchPaste = "watch_paste"
    static let watchClear = "watch_clear"
    static let watchViewKeyInput = "watch_view_key_input"
    static let watchViewKeyPaste = "watch_view_key_paste"
    static let watchViewKeyClear = "watch_view_key_clear"

    static func watchChain(_ blockchainUid: String) -> String {
        "watch_chain_\(blockchainUid)"
    }

    static let watchChainsDone = "watch_chains_done"

    static let backupReveal = "backup_reveal"
    static func backupWord(_ number: Int) -> String {
        "backup_word_\(number)"
    }

    static let backupVerify = "backup_verify"
    static let backupNameInput = "backup_name_input"
    static let backupNamePaste = "backup_name_paste"
    static let backupNameClear = "backup_name_clear"
    static let backupPasswordInput = "backup_password_input"
    static let backupPasswordEye = "backup_password_eye"
    static let backupPasswordConfirmInput = "backup_password_confirm_input"
    static let backupPasswordConfirmEye = "backup_password_confirm_eye"

    static func quizPosition(_ index: Int) -> String {
        "quiz_position_\(index)"
    }

    static func quizOption(_ word: String) -> String {
        "quiz_option_\(word)"
    }

    static func pinKey(_ digit: Int) -> String {
        "pin_key_\(digit)"
    }

    static let pinKeyDelete = "pin_key_delete"
    static let pinTitle = "pin_title"
    static let pinError = "pin_error"
    static let pinAttemptsLeft = "pin_attempts_left"

    static func tab(_ name: String) -> String {
        "tab_\(name.lowercased())"
    }

    static let balanceTotal = "balance_total"

    static let balanceScan = "balance_scan"
    static let balanceReceive = "balance_receive"
    static let balanceSend = "balance_send"
    static let balanceSwap = "balance_swap"

    static let balanceTransactions = "balance_transactions"
    static let balanceManageAccounts = "balance_manage_accounts"
    static let balanceManageCoins = "balance_manage_coins"
    static let balanceSyncIndicator = "balance_sync_indicator"

    static func balanceItem(_ coinCode: String) -> String {
        "balance_item_\(coinCode)"
    }

    static func balanceItemAmount(_ coinCode: String) -> String {
        "balance_item_\(coinCode)_amount"
    }

    static func balanceItemSync(_ coinCode: String, _ state: String) -> String {
        "balance_item_\(coinCode)_\(state)"
    }

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

    static let publicKeysZcashViewingKey = "public_keys_zcash_viewing_key"
    static let zcashViewingKeyValue = "zcash_viewing_key_value"
    static let zcashViewingKeyCopy = "zcash_viewing_key_copy"

    static func manageCoin(_ coinCode: String, _ blockchainUid: String) -> String {
        "manage_coin_\(coinCode)_\(blockchainUid)"
    }

    static let sendAmountInput = "send_amount_input"
    static let sendRecipientRow = "send_recipient_row"
    static let sendNext = "send_next"
    static let sendAction = "send_action"

    static let enterAddressInput = "enter_address_input"
    static let enterAddressSubmit = "enter_address_submit"
    static let enterAddressError = "enter_address_error"
    static let enterAddressScan = "enter_address_scan"
    static let enterAddressPaste = "enter_address_paste"
    static let enterAddressContacts = "enter_address_contacts"
    static let enterAddressClear = "enter_address_clear"

    static let confirmAmount = "confirm_amount"
    static let confirmRecipient = "confirm_recipient"
    static let confirmNetworkFee = "confirm_network_fee"
    static let confirmSend = "confirm_send"

    static let feeSettingsMaxFeeInput = "fee_settings_max_fee_input"
    static let feeSettingsMaxFeeMinus = "fee_settings_max_fee_minus"
    static let feeSettingsMaxFeePlus = "fee_settings_max_fee_plus"
    static let feeSettingsTipsInput = "fee_settings_tips_input"
    static let feeSettingsTipsMinus = "fee_settings_tips_minus"
    static let feeSettingsTipsPlus = "fee_settings_tips_plus"
    static let feeSettingsGasPriceInput = "fee_settings_gas_price_input"
    static let feeSettingsGasPriceMinus = "fee_settings_gas_price_minus"
    static let feeSettingsGasPricePlus = "fee_settings_gas_price_plus"
    static let feeSettingsFeeRateInput = "fee_settings_fee_rate_input"
    static let feeSettingsFeeRateMinus = "fee_settings_fee_rate_minus"
    static let feeSettingsFeeRatePlus = "fee_settings_fee_rate_plus"
    static let feeSettingsMarginalFeeInput = "fee_settings_marginal_fee_input"
    static let feeSettingsMarginalFeeMinus = "fee_settings_marginal_fee_minus"
    static let feeSettingsMarginalFeePlus = "fee_settings_marginal_fee_plus"

    static let nonceInput = "nonce_input"
    static let nonceMinus = "nonce_minus"
    static let noncePlus = "nonce_plus"

    static let resendFeeInput = "resend_fee_input"
    static let resendFeeMinus = "resend_fee_minus"
    static let resendFeePlus = "resend_fee_plus"

    static let txEmpty = "tx_empty"
    static let txFilter = "tx_filter"
    static func txItem(_ uid: String) -> String {
        "tx_item_\(uid.prefix(8))"
    }

    static func txInfoStatus(_ state: String) -> String {
        "tx_info_status_\(state)"
    }

    static func txInfoHash(_ hash: String) -> String {
        "tx_info_hash_\(hash.prefix(8))"
    }

    static func activityTab(_ tab: String) -> String {
        "activity_tab_\(tab)"
    }

    static let activityEmpty = "activity_empty"

    static func activityItem(_ uid: String) -> String {
        "activity_item_\(uid.prefix(8))"
    }

    static let swapTokenIn = "swap_token_in"
    static let swapTokenOut = "swap_token_out"
    static let swapAmountIn = "swap_amount_in"
    static let swapAmountOut = "swap_amount_out"
    static let swapSwitch = "swap_switch"
    static let swapNext = "swap_next"
    static let swapError = "swap_error"
    static let swapProvider = "swap_provider"
    static let slippageInput = "slippage_input"
    static let slippageMinus = "slippage_minus"
    static let slippagePlus = "slippage_plus"
    static func swapCoin(_ coinCode: String, _ blockchainUid: String) -> String {
        "swap_coin_\(coinCode)_\(blockchainUid)"
    }

    static let settingsManageWallets = "settings_manage_wallets"
    static let settingsBlockchain = "settings_blockchain"
    static let settingsSecurity = "settings_security"
    static let settingsPrivacy = "settings_privacy"
    static let settingsContacts = "settings_contacts"
    static let settingsAppSettings = "settings_app_settings"
    static let settingsBackupManager = "settings_backup_manager"
    static let settingsAbout = "settings_about"
    static let settingsDebugSimulateFailSwap = "settings_debug_simulate_fail_swap"
    static let settingsDebugBrandColor = "settings_debug_brand_color"

    static let appearanceBaseCurrency = "appearance_base_currency"
    static func currency(_ code: String) -> String {
        "currency_\(code)"
    }

    static let aboutAppStatus = "about_app_status"
    static let aboutTerms = "about_terms"

    static let securityPasscode = "security_passcode"
    static let securityDisablePasscode = "security_disable_passcode"
    static let securityBiometrics = "security_biometrics"
    static let securityAutolock = "security_autolock"
    static func autolockInterval(_ raw: String) -> String {
        "autolock_\(raw)"
    }

    static func accountRow(_ index: Int) -> String {
        "account_row_\(index)"
    }

    static func accountOptions(_ index: Int) -> String {
        "account_options_\(index)"
    }

    static let accountAdd = "account_add"
    static let accountAddNewWallet = "account_add_new_wallet"
    static let accountAddExistingWallet = "account_add_existing_wallet"

    static let accountManualBackup = "account_manual_backup"
    static let accountUnlink = "account_unlink"
    static let accountNameInput = "account_name_input"
    static let accountSave = "account_save"
    static func unlinkConfirm(_ index: Int) -> String {
        "unlink_confirm_\(index)"
    }

    static let unlinkDelete = "unlink_delete"

    static let birthdayInput = "birthday_input"
    static let birthdayDate = "birthday_date"
    static let birthdayPaste = "birthday_paste"
    static let birthdayClear = "birthday_clear"

    static func indicatorSettingInput(_ field: String) -> String {
        "indicator_setting_input_\(field)"
    }

    static let contactNameInput = "contact_name_input"
    static let contactAddressInput = "contact_address_input"
    static let contactAddressScan = "contact_address_scan"
    static let contactAddressPaste = "contact_address_paste"
    static let contactAddressClear = "contact_address_clear"

    static let checkAddressInput = "check_address_input"
    static let checkAddressScan = "check_address_scan"
    static let checkAddressPaste = "check_address_paste"
    static let checkAddressClear = "check_address_clear"

    static let evmSourceUrlInput = "evm_source_url_input"
    static let evmSourceUrlScan = "evm_source_url_scan"
    static let evmSourceUrlPaste = "evm_source_url_paste"
    static let evmSourceUrlClear = "evm_source_url_clear"
    static let evmSourceAuthInput = "evm_source_auth_input"
    static let evmSourceAuthPaste = "evm_source_auth_paste"
    static let evmSourceAuthClear = "evm_source_auth_clear"
    static let evmSourceAuthEye = "evm_source_auth_eye"

    static let moneroNodeUrlInput = "monero_node_url_input"
    static let moneroNodeUrlScan = "monero_node_url_scan"
    static let moneroNodeUrlPaste = "monero_node_url_paste"
    static let moneroNodeUrlClear = "monero_node_url_clear"
    static let moneroNodeLoginInput = "monero_node_login_input"
    static let moneroNodeLoginPaste = "monero_node_login_paste"
    static let moneroNodeLoginClear = "monero_node_login_clear"
    static let moneroNodePasswordInput = "monero_node_password_input"
    static let moneroNodePasswordPaste = "monero_node_password_paste"
    static let moneroNodePasswordClear = "monero_node_password_clear"
    static let moneroNodePasswordEye = "monero_node_password_eye"

    static let zanoNodeUrlInput = "zano_node_url_input"
    static let zanoNodeUrlScan = "zano_node_url_scan"
    static let zanoNodeUrlPaste = "zano_node_url_paste"
    static let zanoNodeUrlClear = "zano_node_url_clear"
    static let zcashNodeUrlInput = "zcash_node_url_input"
    static let zcashNodeUrlScan = "zcash_node_url_scan"
    static let zcashNodeUrlPaste = "zcash_node_url_paste"
    static let zcashNodeUrlClear = "zcash_node_url_clear"

    static let nearAccountNameInput = "near_account_name_input"
    static let nearAccountNamePaste = "near_account_name_paste"
    static let nearAccountNameClear = "near_account_name_clear"

    static let addTokenInput = "add_token_input"
    static let addTokenScan = "add_token_scan"
    static let addTokenPaste = "add_token_paste"
    static let addTokenClear = "add_token_clear"

    static let moneroAccountNameInput = "monero_account_name_input"
}
