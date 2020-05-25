class AccountCreator {
    private let accountFactory: IAccountFactory
    private let wordsManager: IWordsManager

    init(accountFactory: IAccountFactory, wordsManager: IWordsManager) {
        self.accountFactory = accountFactory
        self.wordsManager = wordsManager
    }

    private func accountType(predefinedAccountType: PredefinedAccountType) throws -> AccountType {
        switch predefinedAccountType {
        case .standard:
            return try createMnemonicAccountType(wordsCount: 12)
        case .eos:
            throw CreateError.eosNotSupported
        case .binance:
            return try createMnemonicAccountType(wordsCount: 24)
        }
    }

    private func createMnemonicAccountType(wordsCount: Int) throws -> AccountType {
        let words = try wordsManager.generateWords(count: wordsCount)
        return .mnemonic(words: words, salt: nil)
    }

}

extension AccountCreator: IAccountCreator {

    func newAccount(predefinedAccountType: PredefinedAccountType) throws -> Account {
        let accountType = try self.accountType(predefinedAccountType: predefinedAccountType)

        return accountFactory.account(
                type: accountType,
                origin: .created,
                backedUp: false
        )
    }

    func restoredAccount(accountType: AccountType) -> Account {
        accountFactory.account(
                type: accountType,
                origin: .restored,
                backedUp: true
        )
    }

}

extension AccountCreator {

    enum CreateError: Error {
        case eosNotSupported
    }

}
