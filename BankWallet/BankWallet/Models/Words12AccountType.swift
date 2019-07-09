class Words12AccountType: IPredefinedAccountType {
    let title = "key_type.12_words"
    let coinCodes = "BTC, BCH, DASH, ETH, ERC-20"

    var defaultAccountType: DefaultAccountType? {
        return .mnemonic(wordsCount: 12)
    }

}
