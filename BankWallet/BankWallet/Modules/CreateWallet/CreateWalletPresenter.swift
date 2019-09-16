class CreateWalletPresenter {
    weak var view: ICreateWalletView?

    private let interactor: ICreateWalletInteractor
    private let router: ICreateWalletRouter
    private let state: CreateWalletState
    private let viewItemFactory: CreateWalletViewItemFactory

    init(interactor: ICreateWalletInteractor, router: ICreateWalletRouter, state: CreateWalletState = .init(), viewItemFactory: CreateWalletViewItemFactory = .init()) {
        self.interactor = interactor
        self.router = router
        self.state = state
        self.viewItemFactory = viewItemFactory
    }

}

extension CreateWalletPresenter: ICreateWalletViewDelegate {

    func viewDidLoad() {
        let initialSelectedIndex = 0
        let featuredCoins = interactor.featuredCoins

        state.coins = featuredCoins
        state.selectedIndex = initialSelectedIndex

        let viewItems = viewItemFactory.viewItems(coins: featuredCoins, selectedIndex: initialSelectedIndex)
        view?.set(viewItems: viewItems)
    }

    func didTap(index: Int) {
        state.selectedIndex = index

        let viewItems = viewItemFactory.viewItems(coins: state.coins, selectedIndex: index)
        view?.set(viewItems: viewItems)
    }

    func didTapCreateButton() {
        interactor.createWallet(coin: state.coins[state.selectedIndex])
        router.showMain()
    }

}
