class AddTokenSelectorPresenter {
    private let router: IAddTokenSelectorRouter

    init(router: IAddTokenSelectorRouter) {
        self.router = router
    }

}

extension AddTokenSelectorPresenter: IAddTokenSelectorViewDelegate {

    func onTapErc20() {
        router.closeAndShowAddErc20Token()
    }

    func onTapBinance() {
        router.closeAndShowAddBinanceToken()
    }

    func onTapClose() {
        router.close()
    }

}
