import Foundation
import RxSwift

class WalletPresenter {

    let interactor: IWalletInteractor
    let router: IWalletRouter
    weak var view: IWalletView?

    var coinValues = [Coin: CoinValue]()
    var rates = [Coin: Double]()
    var progressSubjects = [Coin: BehaviorSubject<Double>]()
    var currency: Currency = DollarCurrency()

    init(interactor: IWalletInteractor, router: IWalletRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension WalletPresenter: IWalletInteractorDelegate {

    func didInitialFetch(coinValues: [Coin: CoinValue], rates: [Coin: Double], progressSubjects: [Coin: BehaviorSubject<Double>], currency: Currency) {
        self.coinValues = coinValues
        self.rates = rates
        self.progressSubjects = progressSubjects
        self.currency = currency

        updateView()
    }

    func didUpdate(coinValue: CoinValue) {
        coinValues[coinValue.coin] = coinValue

        updateView()
    }

    func didUpdate(rates: [Coin: Double]) {
        self.rates = rates

        updateView()
    }

    private func updateView() {
        var totalBalance: Double = 0

        var viewItems = [WalletBalanceViewItem]()

        for (coin, coinValue) in coinValues {
            let rate = rates[coinValue.coin]

            viewItems.append(WalletBalanceViewItem(
                    coinValue: coinValue,
                    exchangeValue: rate.map { CurrencyValue(currency: currency, value: $0) },
                    currencyValue: rate.map { CurrencyValue(currency: currency, value: coinValue.value * $0) },
                    progressSubject: progressSubjects[coin]
            ))

            if let rate = rate {
                totalBalance += coinValue.value * rate
            }
        }

        view?.show(totalBalance: CurrencyValue(currency: currency, value: totalBalance))
        view?.show(walletBalances: viewItems)
    }

}

extension WalletPresenter: IWalletViewDelegate {

    func viewDidLoad() {
        interactor.notifyWalletBalances()
    }

    func refresh() {
        interactor.refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.view?.didRefresh()
        })
    }

    func onReceive(for coin: Coin) {
        router.onReceive(for: coin)
    }

    func onPay(for coin: Coin) {
        router.onSend(for: coin)
    }

}
