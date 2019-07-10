class AccountCreator {
    private let accountManager: IAccountManager
    private let accountFactory: IAccountFactory
    private let wordsManager: IWordsManager

    init(accountManager: IAccountManager, accountFactory: IAccountFactory, wordsManager: IWordsManager) {
        self.accountManager = accountManager
        self.accountFactory = accountFactory
        self.wordsManager = wordsManager
    }

    private func createMnemonicAccount(wordsCount: Int) throws -> Account {
        let words = try wordsManager.generateWords(count: wordsCount)

        return accountFactory.account(
                type: .mnemonic(words: words, derivation: .bip44, salt: nil),
                backedUp: false,
                defaultSyncMode: .new
        )
    }

}

extension AccountCreator: IAccountCreator {

    func createRestoredAccount(accountType: AccountType, syncMode: SyncMode?) -> Account {
        let account = accountFactory.account(
                type: accountType,
                backedUp: true,
                defaultSyncMode: syncMode
        )

        accountManager.save(account: account)

        return account
    }

    func createNewAccount(defaultAccountType: DefaultAccountType) throws -> Account {
        let account: Account

        switch defaultAccountType {
        case let .mnemonic(wordsCount):
            account = try createMnemonicAccount(wordsCount: wordsCount)
        }

        accountManager.save(account: account)

        return account
    }

}
