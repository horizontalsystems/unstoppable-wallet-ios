class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let accountCreator: IAccountCreator

    init(accountCreator: IAccountCreator) {
        self.accountCreator = accountCreator
    }
}

extension RestoreInteractor: IRestoreInteractor {

    var allTypes: [PredefinedAccountType] {
        return PredefinedAccountType.allCases
    }

    func createAccount(accountType: AccountType, syncMode: SyncMode?) {
        accountCreator.createRestoredAccount(accountType: accountType, syncMode: syncMode)
    }

}
