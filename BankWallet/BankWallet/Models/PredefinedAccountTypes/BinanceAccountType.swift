class BinanceAccountType: IPredefinedAccountType {
    let title = "Binance"
    let coinCodes = "BNB, BEP-2 tokens"

    var defaultAccountType: DefaultAccountType {
        .mnemonic(wordsCount: 24)
    }

    func supports(accountType: AccountType) -> Bool {
        if case let .mnemonic(words, _, _) = accountType {
            return words.count == 24
        }

        return false
    }

}
