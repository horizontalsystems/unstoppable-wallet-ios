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

    func onTapBep20() {
        router.closeAndShowAddBep20Token()
    }

    func onTapBep2() {
        router.closeAndShowAddBep2Token()
    }

    func onTapClose() {
        router.close()
    }

}
