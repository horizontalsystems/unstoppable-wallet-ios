class UnstoppableAccountType: IPredefinedAccountType {
    let title = "Unstoppable"
    let coinCodes = "BTC, ETH, BCH, DASH, ERC20 tokens"

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
