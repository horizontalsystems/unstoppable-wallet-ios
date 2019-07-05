class CreateAccountInteractor {
    weak var delegate: ICreateAccountInteractorDelegate?

    private let accountCreator: IAccountCreator
    private let accountFactory = AccountFactory()

    init(accountCreator: IAccountCreator) {
        self.accountCreator = accountCreator
    }

}

extension CreateAccountInteractor: ICreateAccountInteractor {

    func createAccount(type: PredefinedAccountType) throws -> Account {
        return try accountCreator.createNewAccount(type: type)
    }

}
