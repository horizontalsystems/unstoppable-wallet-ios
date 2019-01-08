import RxSwift

class BalancePresenter {
    private let interactor: IBalanceInteractor
    private let router: IBalanceRouter

    weak var view: IBalanceView?

    init(interactor: IBalanceInteractor, router: IBalanceRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func updateView() {
        var totalBalance: Double = 0

        var viewItems = [BalanceViewItem]()
        let currency = interactor.baseCurrency

        var allSynced = true

        for wallet in interactor.wallets {
            let balance = wallet.adapter.balance
            let rate = interactor.rate(forCoin: wallet.coinCode)

            var rateExpired = true

            if let rate = rate {
                rateExpired = rate.expired
                totalBalance += balance * rate.value
            }

            var syncing = false
            if case .syncing = wallet.adapter.state {
                syncing = true
            }

            viewItems.append(BalanceViewItem(
                    coinValue: CoinValue(coinCode: wallet.coinCode, value: balance),
                    exchangeValue: rate.map { CurrencyValue(currency: currency, value: $0.value) },
                    currencyValue: rate.map { CurrencyValue(currency: currency, value: balance * $0.value) },
                    state: wallet.adapter.state,
                    rateExpired: rateExpired,
                    refreshVisible: wallet.adapter.refreshable && !syncing
            ))

            if case .synced = wallet.adapter.state {
                // do nothing
            } else {
                allSynced = false
            }

            allSynced = allSynced && !rateExpired
        }

        view?.show(totalBalance: CurrencyValue(currency: currency, value: totalBalance), upToDate: allSynced)
        view?.show(items: viewItems)
    }

}

extension BalancePresenter: IBalanceInteractorDelegate {

    func didUpdate() {
        updateView()
    }

}

extension BalancePresenter: IBalanceViewDelegate {

    func viewDidLoad() {
        view?.set(title: "balance.title")

        updateView()
    }

    func onRefresh(for coinCode: CoinCode) {
        interactor.refresh(coinCode: coinCode)
    }

    func onReceive(for coinCode: CoinCode) {
        router.openReceive(for: coinCode)
    }

    func onPay(for coinCode: CoinCode) {
        router.openSend(for: coinCode)
    }

    func onOpenManageCoins() {
        router.openManageCoins()
    }

}
