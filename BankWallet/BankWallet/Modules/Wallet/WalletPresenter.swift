import RxSwift

class WalletPresenter {
    private let interactor: IWalletInteractor
    private let router: IWalletRouter

    weak var view: IWalletView?

    init(interactor: IWalletInteractor, router: IWalletRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func updateView() {
        var totalBalance: Double = 0

        var viewItems = [WalletViewItem]()
        let currency = interactor.baseCurrency

        for coinValue in interactor.coinValues {
            let rate = interactor.rate(forCoin: coinValue.coin)

            var rateExpired = false

            if let rate = rate {
                let diff = Date().timeIntervalSince1970 - rate.timestamp
                rateExpired = diff > 60 * 10

                totalBalance += coinValue.value * rate.value
            }

            viewItems.append(WalletViewItem(
                    coinValue: coinValue,
                    exchangeValue: rate.map { CurrencyValue(currency: currency, value: $0.value) },
                    currencyValue: rate.map { CurrencyValue(currency: currency, value: coinValue.value * $0.value) },
                    progressSubject: interactor.progressSubject(forCoin: coinValue.coin),
                    rateExpired: rateExpired
            ))
        }

        view?.show(totalBalance: CurrencyValue(currency: currency, value: totalBalance))
        view?.show(wallets: viewItems)
    }

}

extension WalletPresenter: IWalletInteractorDelegate {

    func didUpdate() {
        updateView()
    }

    func didRefresh() {
        view?.didRefresh()
    }

}

extension WalletPresenter: IWalletViewDelegate {

    func viewDidLoad() {
        view?.set(title: "wallet.title")

        updateView()
    }

    func refresh() {
        interactor.refresh()
    }

    func onReceive(for coin: Coin) {
        router.openReceive(for: coin)
    }

    func onPay(for coin: Coin) {
        router.openSend(for: coin)
    }

}
