class PredefinedAccountTypeManager {
    private let appConfigProvider: IAppConfigProvider
    private let accountManager: IAccountManager
    private let accountCreator: IAccountCreator
    private let wordsManager: IWordsManager

    init(appConfigProvider: IAppConfigProvider, accountManager: IAccountManager, accountCreator: IAccountCreator, wordsManager: IWordsManager) {
        self.appConfigProvider = appConfigProvider
        self.accountManager = accountManager
        self.accountCreator = accountCreator
        self.wordsManager = wordsManager
    }

    private func accountType(predefinedAccountType: IPredefinedAccountType) throws -> AccountType? {
        guard let defaultAccountType = predefinedAccountType.defaultAccountType else {
            return nil
        }

        switch defaultAccountType {
        case let .mnemonic(wordsCount):
            return try createMnemonicAccountType(wordsCount: wordsCount)
        }
    }

    private func createMnemonicAccountType(wordsCount: Int) throws -> AccountType {
        let words = try wordsManager.generateWords(count: wordsCount)
        return .mnemonic(words: words, derivation: .bip44, salt: nil)
    }

}

extension PredefinedAccountTypeManager: IPredefinedAccountTypeManager {

    var allTypes: [IPredefinedAccountType] {
        return appConfigProvider.predefinedAccountTypes
    }

    func account(predefinedAccountType: IPredefinedAccountType) -> Account? {
        return accountManager.accounts.first { predefinedAccountType.supports(accountType: $0.type) }
    }

    func createAccount(predefinedAccountType: IPredefinedAccountType) throws -> Account? {
        guard let accountType = try accountType(predefinedAccountType: predefinedAccountType) else {
            return nil
        }

        return accountCreator.createNewAccount(accountType: accountType)
    }

    func createAllAccounts() throws {
        for predefinedAccountType in allTypes {
            _ = try createAccount(predefinedAccountType: predefinedAccountType)
        }
    }

}
