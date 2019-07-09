class Words24AccountType: IPredefinedAccountType {
    let title = "key_type.24_words"
    let coinCodes = "BNB"

    var defaultAccountType: DefaultAccountType? {
        return .mnemonic(wordsCount: 24)
    }

}
