class BinanceAccountType: IPredefinedAccountType {
    let title = "Binance"
    let coinCodes = "GTO, ANKR, BTCB, CRPT, CAS"

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
