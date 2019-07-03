class CreateAccountInteractor {
    weak var delegate: ICreateAccountInteractorDelegate?

    private let accountManager: IAccountManager
    private let accountCreator: AccountCreator

    init(accountManager: IAccountManager, accountCreator: AccountCreator) {
        self.accountManager = accountManager
        self.accountCreator = accountCreator
    }

}

extension CreateAccountInteractor: ICreateAccountInteractor {

    func createAccount(coin: Coin) -> Account? {
        guard let account = accountCreator.account(coin: coin) else {
            return nil
        }

        accountManager.save(account: account)

        return account
    }

}
