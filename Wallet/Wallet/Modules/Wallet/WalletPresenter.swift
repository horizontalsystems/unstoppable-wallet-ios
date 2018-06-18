import Foundation

class WalletPresenter {

    let interactor: IWalletInteractor
    let router: IWalletRouter
    weak var view: IWalletView?

    init(interactor: IWalletInteractor, router: IWalletRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension WalletPresenter: IWalletInteractorDelegate {

    func didFetch(walletBalances: [WalletBalanceItem]) {
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

    private func viewModel(forBalance balance: WalletBalanceItem) -> WalletBalanceViewModel {
        return WalletBalanceViewModel(
                coinValue: balance.coinValue,
                convertedValue: CurrencyValue(currency: balance.conversionCurrency, value: balance.coinValue.value * balance.conversionRate),
                rate: CurrencyValue(currency: balance.conversionCurrency, value: balance.conversionRate)
        )
    }

}

extension WalletPresenter: IWalletViewDelegate {

    func viewDidLoad() {
        interactor.notifyWalletBalances()
    }

}
