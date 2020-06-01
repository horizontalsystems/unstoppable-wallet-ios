class AddTokenPresenter {
    private let router: IAddTokenRouter

    init(router: IAddTokenRouter) {
        self.router = router
    }

}

extension AddTokenPresenter: IAddTokenViewDelegate {

    func onTapErc20() {
        router.closeAndShowAddErc20Token()
    }

    func onTapClose() {
        router.close()
    }

}
