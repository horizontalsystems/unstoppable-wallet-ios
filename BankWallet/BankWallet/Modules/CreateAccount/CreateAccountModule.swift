protocol ICreateAccountView: class {
}

protocol ICreateAccountViewDelegate {
    func didTapNew()
    func didTapRestore()
}

protocol ICreateAccountInteractor {
    func createAccount(coin: Coin) -> Account?
}

protocol ICreateAccountInteractorDelegate: class {
}

protocol ICreateAccountRouter {
    func dismiss(account: Account, coin: Coin)

}

protocol ICreateAccountDelegate: class {
    func onCreate(account: Account, coin: Coin)
}
