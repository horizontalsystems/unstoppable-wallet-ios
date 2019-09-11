class BaseCurrencySettingsPresenter {
    weak var view: IBaseCurrencySettingsView?

    private let router: IBaseCurrencySettingsRouter
    private let interactor: IBaseCurrencySettingsInteractor

    private let currencies: [Currency]

    init(router: IBaseCurrencySettingsRouter, interactor: IBaseCurrencySettingsInteractor) {
        self.router = router
        self.interactor = interactor

        currencies = interactor.currencies
    }

}

extension BaseCurrencySettingsPresenter: IBaseCurrencySettingsViewDelegate {

    func viewDidLoad() {
        let baseCurrency = interactor.baseCurrency

        let viewItems = currencies.map { currency in
            CurrencyViewItem(code: currency.code, symbol: currency.symbol, selected: currency == baseCurrency)
        }

        view?.show(viewItems: viewItems)
    }

    func didSelect(index: Int) {
        let selectedCurrency = currencies[index]

        if selectedCurrency != interactor.baseCurrency {
            interactor.baseCurrency = selectedCurrency
        }

        router.dismiss()
    }

}
