class CreateAccountInteractor {
    weak var delegate: ICreateAccountInteractorDelegate?

    private let accountManager: IAccountManager
    private let wordsManager: IWordsManager
    private let accountFactory = AccountFactory()

    init(accountManager: IAccountManager, wordsManager: IWordsManager) {
        self.accountManager = accountManager
        self.wordsManager = wordsManager
    }

    private func createMnemonicAccount() throws -> Account {
        let words = try wordsManager.generateWords()
        let type: AccountType = .mnemonic(words: words, derivation: .bip44, salt: nil)
        return accountFactory.account(type: type, backedUp: false, defaultSyncMode: .new)
    }

}

extension CreateAccountInteractor: ICreateAccountInteractor {

    func createAccount(coin: Coin) -> Account? {
        var account: Account?

        switch coin.type.predefinedAccountType {
        case .mnemonic:
            account = try? createMnemonicAccount()
        case .eos: ()
        case .binance: ()
        }

        if let account = account {
            accountManager.save(account: account)
        }

        return account
    }

}
