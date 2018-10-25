import RxSwift

class WalletPresenter {
    private let interactor: IWalletInteractor
    private let router: IWalletRouter

    weak var view: IWalletView?

    private var coinValues: [CoinValue]
    private var rates: [Coin: CurrencyValue]
    private var progressSubjects: [Coin: BehaviorSubject<Double>]

    init(interactor: IWalletInteractor, router: IWalletRouter) {
        self.interactor = interactor
        self.router = router

        coinValues = interactor.coinValues
        rates = interactor.rates
        progressSubjects = interactor.progressSubjects
    }

    private func updateView() {
        var totalBalance: Double = 0

        var viewItems = [WalletViewItem]()
        var currency: Currency?

        for coinValue in coinValues {
            let rate = rates[coinValue.coin]

            viewItems.append(WalletViewItem(
                    coinValue: coinValue,
                    exchangeValue: rate,
                    currencyValue: rate.map { CurrencyValue(currency: $0.currency, value: coinValue.value * $0.value) },
                    progressSubject: progressSubjects[coinValue.coin]
            ))

            if let rate = rate {
                totalBalance += coinValue.value * rate.value
                currency = rate.currency
            }
        }

        if let currency = currency {
            view?.show(totalBalance: CurrencyValue(currency: currency, value: totalBalance))
        }

        view?.show(wallets: viewItems)
    }

}

extension WalletPresenter: IWalletInteractorDelegate {

    func didUpdate(coinValue: CoinValue) {
        if let index = coinValues.firstIndex(where: { $0.coin == coinValue.coin }) {
            coinValues[index] = coinValue
            updateView()
        }
    }

    func didUpdate(rates: [Coin: CurrencyValue]) {
        self.rates = rates

        updateView()
    }

    func didUpdateCoinValues() {
        coinValues = interactor.coinValues
        progressSubjects = interactor.progressSubjects

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
