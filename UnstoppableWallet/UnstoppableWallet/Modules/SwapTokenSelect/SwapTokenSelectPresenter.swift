class SwapTokenSelectPresenter {
    weak var view: ISwapTokenSelectView?

    private let interactor: ISwapTokenSelectInteractor
    private let router: ISwapTokenSelectRouter
    private let factory: ICoinBalanceViewItemFactory
    private let delegate: ICoinSelectDelegate

    private let accountCoins: Bool
    private let exclude: [Coin]

    init(interactor: ISwapTokenSelectInteractor, router: ISwapTokenSelectRouter, factory: ICoinBalanceViewItemFactory, delegate: ICoinSelectDelegate, accountCoins: Bool, exclude: [Coin]) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.delegate = delegate

        self.accountCoins = accountCoins
        self.exclude = exclude
    }

    private func syncViewItems() {
        let viewItems = interactor.coins(accountCoins: accountCoins, exclude: exclude).map { factory.viewItem(item: $0) }

        view?.set(viewItems: viewItems)
    }

}

extension SwapTokenSelectPresenter: ISwapTokenSelectViewDelegate {

    func onLoad() {
        syncViewItems()
    }

    func onSelect(coin: Coin) {
        delegate.didSelect(accountCoins: accountCoins, coin: coin)

        router.close()
    }

    func onTapClose() {
        router.close()
    }

}
