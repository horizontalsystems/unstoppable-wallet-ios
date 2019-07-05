protocol ICreateAccountView: class {
    func setTitle(for coin: Coin)
    func show(error: Error)
}

protocol ICreateAccountViewDelegate {
    var showNew: Bool { get }

    func viewDidLoad()
    func didTapNew()
    func didTapRestore()
}

protocol ICreateAccountInteractor {
    func createAccount(type: PredefinedAccountType) throws -> Account
}

protocol ICreateAccountInteractorDelegate: class {
}

protocol ICreateAccountRouter {
    func dismiss(account: Account, coin: Coin)

}

protocol ICreateAccountDelegate: class {
    func onCreate(account: Account, coin: Coin)
}
