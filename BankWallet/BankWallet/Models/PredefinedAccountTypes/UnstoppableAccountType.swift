class UnstoppableAccountType: IPredefinedAccountType {
    let title = "Unstoppable"
    let coinCodes = "BTC, BCH, DASH, ETH, ERC-20"

    var defaultAccountType: DefaultAccountType {
        .mnemonic(wordsCount: 12)
    }

    func supports(accountType: AccountType) -> Bool {
        if case let .mnemonic(words, _, _) = accountType {
            return words.count == 12
        }

        return false
    }

}
