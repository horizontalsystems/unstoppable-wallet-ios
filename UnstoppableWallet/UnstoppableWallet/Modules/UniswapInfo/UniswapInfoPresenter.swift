class UniswapInfoPresenter {
    private let uniswapWebSiteLink = "https://uniswap.org/"

    private let router: IUniswapInfoRouter

    init(router: IUniswapInfoRouter) {
        self.router = router
    }

}

extension UniswapInfoPresenter: IUniswapInfoViewDelegate {

    func onTapLink() {
        router.open(url: uniswapWebSiteLink)
    }

    func onTapClose() {
        router.close()
    }

}
