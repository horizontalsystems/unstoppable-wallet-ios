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

        var allSynced = true

        for wallet in interactor.wallets {
            let balance = wallet.adapter.balance
            let rate = interactor.rate(forCoin: wallet.coin)

            var rateExpired = false

            if let rate = rate {
                let diff = Date().timeIntervalSince1970 - rate.timestamp
                rateExpired = diff > 60 * 10

                totalBalance += balance * rate.value
            }

            viewItems.append(WalletViewItem(
                    coinValue: CoinValue(coin: wallet.coin, value: balance),
                    exchangeValue: rate.map { CurrencyValue(currency: currency, value: $0.value) },
                    currencyValue: rate.map { CurrencyValue(currency: currency, value: balance * $0.value) },
                    state: wallet.adapter.state,
                    rateExpired: rateExpired
            ))

            if case .syncing = wallet.adapter.state, rate != nil {
                allSynced = false
            }
        }

        view?.show(totalBalance: allSynced ? CurrencyValue(currency: currency, value: totalBalance) : nil)
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
