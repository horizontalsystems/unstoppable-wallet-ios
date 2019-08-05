class Words24AccountType: IPredefinedAccountType {
    let title = "key_type.binance"
    let coinCodes = "key_type.binance.text"

    var defaultAccountType: DefaultAccountType {
        return .mnemonic(wordsCount: 24)
    }

    func supports(accountType: AccountType) -> Bool {
        if case let .mnemonic(words, _, _) = accountType {
            return words.count == 24
        }

        return false
    }

}
