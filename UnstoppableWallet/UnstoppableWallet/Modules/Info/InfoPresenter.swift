class InfoPresenter {
    private var link: String?

    private let router: IInfoRouter

    init(router: IInfoRouter, url: String? = nil) {
        self.router = router
        link = url
    }

}

extension InfoPresenter: IInfoViewDelegate {

    func onTapLink() {
        guard let link = link else {
            return
        }

        router.open(url: link)
    }

    func onTapClose() {
        router.close()
    }

}
