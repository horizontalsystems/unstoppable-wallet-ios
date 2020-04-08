class PrivacyPresenter {
    weak var view: IPrivacyView?

    private let interactor: IPrivacyInteractor
    private let router: IPrivacyRouter

    init(interactor: IPrivacyInteractor, router: IPrivacyRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension PrivacyPresenter: IPrivacyViewDelegate {

    func onLoad() {
        view?.set(sortingMode: "default")
        view?.set(connectionItems: [
            PrivacyViewItem(iconName: "ETH", title: "Ethereum", value: "Incubed", changable: true),
            PrivacyViewItem(iconName: "EOS", title: "EOS", value: "eos.greymass.com", changable: false),
            PrivacyViewItem(iconName: "BNB", title: "Binance", value: "dex.binance.com", changable: false)
        ])
        view?.set(syncModeItems: [
            PrivacyViewItem(iconName: "BTC", title: "Bitcoin", value: "API", changable: true),
            PrivacyViewItem(iconName: "LTC", title: "Litecoin", value: "API", changable: true),
            PrivacyViewItem(iconName: "BCH", title: "Bitcoin Cash", value: "API", changable: true),
            PrivacyViewItem(iconName: "DASH", title: "Dash", value: "API", changable: true),
        ])

        view?.updateUI()
    }

    func onSelectSortMode() {

    }

    func onSelectConnection(index: Int) {

    }

    func onSelectSync(index: Int) {
    }

}
