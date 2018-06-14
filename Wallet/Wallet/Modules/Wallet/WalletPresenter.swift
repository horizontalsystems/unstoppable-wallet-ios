import Foundation

class WalletPresenter {

    let delegate: WalletPresenterDelegate
    let router: WalletRouterProtocol
    weak var view: WalletViewProtocol?

    init(delegate: WalletPresenterDelegate, router: WalletRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension WalletPresenter: WalletPresenterProtocol {

    func didFetch(walletBalances: [WalletBalance]) {
        var total: Double = 0
        var viewModels = [WalletBalanceViewModel]()

        for balance in walletBalances {
            total += balance.coinValue.value * balance.conversionRate
            viewModels.append(viewModel(forBalance: balance))
        }

        if let currency = walletBalances.first?.conversionCurrency {
            view?.show(totalBalance: CurrencyValue(currency: currency, value: total))
        }

        view?.show(walletBalances: viewModels)
    }

    private func viewModel(forBalance balance: WalletBalance) -> WalletBalanceViewModel {
        return WalletBalanceViewModel(
                coinValue: balance.coinValue,
                convertedValue: CurrencyValue(currency: balance.conversionCurrency, value: balance.coinValue.value * balance.conversionRate),
                rate: CurrencyValue(currency: balance.conversionCurrency, value: balance.conversionRate)
        )
    }

}

extension WalletPresenter: WalletViewDelegate {

    func viewDidLoad() {
        delegate.fetchWalletBalances()
    }

}
