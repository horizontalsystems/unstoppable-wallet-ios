class BinanceAccountType: IPredefinedAccountType {
    let title = "Binance Chain"
    let coinCodes = "BNB, BEP-2"

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
