class Words12AccountType: IPredefinedAccountType {
    let title = "key_type.12_words"
    let coinCodes = "key_type.12_words.text"

    var defaultAccountType: DefaultAccountType? {
        return .mnemonic(wordsCount: 12)
    }

    func supports(accountType: AccountType) -> Bool {
        if case let .mnemonic(words, _, _) = accountType {
            return words.count == 12
        }

        return false
    }

}
