class AccountCreator {
    private let accountManager: IAccountManager
    private let accountFactory: IAccountFactory
    private let wordsManager: IWordsManager
    private let defaultWalletCreator: IDefaultWalletCreator

    init(accountManager: IAccountManager, accountFactory: IAccountFactory, wordsManager: IWordsManager, defaultWalletCreator: IDefaultWalletCreator) {
        self.accountManager = accountManager
        self.accountFactory = accountFactory
        self.wordsManager = wordsManager
        self.defaultWalletCreator = defaultWalletCreator
    }

    private func createNewAccount(defaultAccountType: DefaultAccountType) throws -> Account {
        let accountType = try createAccountType(defaultAccountType: defaultAccountType)
        return createAccount(accountType: accountType, backedUp: false, defaultSyncMode: .new)
    }

    private func createAccount(accountType: AccountType, backedUp: Bool, defaultSyncMode: SyncMode?) -> Account {
        let account = accountFactory.account(
                type: accountType,
                backedUp: backedUp,
                defaultSyncMode: defaultSyncMode
        )

        accountManager.create(account: account)

        return account
    }

    private func createAccountType(defaultAccountType: DefaultAccountType) throws -> AccountType {
        switch defaultAccountType {
        case let .mnemonic(wordsCount):
            return try createMnemonicAccountType(wordsCount: wordsCount)
        case .eos:
            throw CreateError.eosNotSupported
        }
    }

    private func createMnemonicAccountType(wordsCount: Int) throws -> AccountType {
        let words = try wordsManager.generateWords(count: wordsCount)
        return .mnemonic(words: words, derivation: .bip44, salt: nil)
    }

}

extension AccountCreator: IAccountCreator {

    func createNewAccount(defaultAccountType: DefaultAccountType, createDefaultWallets: Bool) throws -> Account {
        let account = try createNewAccount(defaultAccountType: defaultAccountType)

        if createDefaultWallets {
            defaultWalletCreator.createWallets(account: account)
        }

        return account
    }

    func createNewAccount(coin: Coin) throws {
        let account = try createNewAccount(defaultAccountType: coin.type.defaultAccountType)

        defaultWalletCreator.createWallet(account: account, coin: coin)
    }

    func createRestoredAccount(accountType: AccountType, defaultSyncMode: SyncMode?, createDefaultWallets: Bool) -> Account {
        let account = createAccount(accountType: accountType, backedUp: true, defaultSyncMode: defaultSyncMode)

        if createDefaultWallets {
            defaultWalletCreator.createWallets(account: account)
        }

        return account
    }

}

extension AccountCreator {

    enum CreateError: Error {
        case eosNotSupported
    }

}
