import Foundation

class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider
    private let accountManager: IAccountManager
    private let accountFactory = AccountFactory()

    init(wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider, accountManager: IAccountManager) {
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
        self.accountManager = accountManager
    }

}

extension RestoreInteractor: IRestoreInteractor {

    var defaultWords: [String] {
        return appConfigProvider.defaultWords
    }

    func validate(words: [String]) throws {
        try wordsManager.validate(words: words)
    }

    func save(accountType: AccountType, syncMode: SyncMode?) {
        let account = accountFactory.account(type: accountType, backedUp: true, defaultSyncMode: syncMode)
        accountManager.save(account: account)
    }

}
