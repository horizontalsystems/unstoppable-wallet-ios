class CreateAccountPresenter {
    weak var view: ICreateAccountView?

    private let router: ICreateAccountRouter
    private let accountCreator: IAccountCreator

    private let coin: Coin

    init(coin: Coin, router: ICreateAccountRouter, accountCreator: IAccountCreator) {
        self.coin = coin
        self.router = router
        self.accountCreator = accountCreator
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
            let account = try accountCreator.createNewAccount(type: coin.type.predefinedAccountType)
            router.dismiss(account: account, coin: coin)
        } catch {
            view?.show(error: error)
        }
    }

    func didTapRestore() {
        print("Restore")
    }

}
