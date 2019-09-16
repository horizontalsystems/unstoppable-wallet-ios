class CreateWalletPresenter {
    weak var view: ICreateWalletView?

    private let interactor: ICreateWalletInteractor
    private let router: ICreateWalletRouter
    private let state: CreateWalletState

    init(interactor: ICreateWalletInteractor, router: ICreateWalletRouter, state: CreateWalletState = .init()) {
        self.interactor = interactor
        self.router = router
        self.state = state
    }

}

extension CreateWalletPresenter: ICreateWalletViewDelegate {

    func viewDidLoad() {
        let featuredCoins = interactor.featuredCoins

        state.coins = featuredCoins

        let viewItems = featuredCoins.map {
            CreateWalletViewItem(title: $0.title, code: $0.code)
        }
        view?.set(viewItems: viewItems)
    }

    func didTap(index: Int) {
        interactor.createWallet(coin: state.coins[index])
        router.showMain()
    }

}
