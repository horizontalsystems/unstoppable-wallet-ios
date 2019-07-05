class CreateAccountPresenter {
    weak var view: ICreateAccountView?

    private let router: ICreateAccountRouter
    private let interactor: ICreateAccountInteractor

    private let coin: Coin

    init(router: ICreateAccountRouter, interactor: ICreateAccountInteractor, coin: Coin) {
        self.router = router
        self.interactor = interactor
        self.coin = coin
    }

}

extension CreateAccountPresenter: ICreateAccountViewDelegate {

    var showNew: Bool {
        return coin.type.canCreateAccount
    }

    func viewDidLoad() {
        view?.setTitle(for: coin)
    }

    func didTapNew() {
        do {
            let account = try interactor.createAccount(type: coin.type.predefinedAccountType)
            router.dismiss(account: account, coin: coin)
        } catch {
            view?.show(error: error)
        }
    }

    func didTapRestore() {
        print("Restore")
    }

}

extension CreateAccountPresenter: ICreateAccountInteractorDelegate {
}
