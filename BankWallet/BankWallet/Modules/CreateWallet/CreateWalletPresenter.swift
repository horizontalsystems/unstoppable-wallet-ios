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

        state.coins = featuredCoins.map { $0.coin }

        let viewItems = featuredCoins.map {
            CreateWalletViewItem(title: $0.coin.title, code: $0.coin.code, selected: $0.enabledByDefault)
        }
        view?.set(viewItems: viewItems)

        var enabledIndexes = Set<Int>()

        for (index, featuredCoin) in featuredCoins.enumerated() {
            if featuredCoin.enabledByDefault {
                enabledIndexes.insert(index)
            }
        }

        state.enabledIndexes = enabledIndexes
        view?.set(createButtonEnabled: !enabledIndexes.isEmpty)
    }

    func didToggle(index: Int, isOn: Bool) {
        var enabledIndexes = state.enabledIndexes

        if isOn {
            if enabledIndexes.isEmpty {
                view?.set(createButtonEnabled: true)
            }

            enabledIndexes.insert(index)
        } else {
            enabledIndexes.remove(index)

            if enabledIndexes.isEmpty {
                view?.set(createButtonEnabled: false)
            }
        }

        state.enabledIndexes = enabledIndexes
    }

    func didTapCreateButton() {
        let coins = state.coins
        var enabledCoins = [Coin]()

        for index in state.enabledIndexes {
            enabledCoins.append(coins[index])
        }

        interactor.createWallet(coins: enabledCoins)

        router.showMain()
    }

}
