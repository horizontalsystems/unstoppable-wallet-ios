class SwapTokenSelectPresenter {
    weak var view: ISwapTokenSelectView?

    private let interactor: ISwapTokenSelectInteractor
    private let router: ISwapTokenSelectRouter
    private let factory: ICoinBalanceViewItemFactory
    private let delegate: ICoinSelectDelegate

    private let path: SwapPath
    private let exclude: [Coin]

    init(interactor: ISwapTokenSelectInteractor, router: ISwapTokenSelectRouter, factory: ICoinBalanceViewItemFactory, delegate: ICoinSelectDelegate, path: SwapPath, exclude: [Coin]) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.delegate = delegate

        self.path = path
        self.exclude = exclude
    }

    private func syncViewItems() {
        let viewItems = interactor.coins(path: path, exclude: exclude).map { factory.viewItem(item: $0) }

        view?.set(viewItems: viewItems)
    }

}

extension SwapTokenSelectPresenter: ISwapTokenSelectViewDelegate {

    func onLoad() {
        syncViewItems()
    }

    func onSelect(coin: Coin) {
        delegate.didSelect(path: path, coin: coin)

        router.close()
    }

    func onTapClose() {
        router.close()
    }

}
