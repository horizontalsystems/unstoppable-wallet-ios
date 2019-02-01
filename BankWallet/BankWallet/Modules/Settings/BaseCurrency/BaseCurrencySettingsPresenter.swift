class BaseCurrencySettingsPresenter {
    private let router: IBaseCurrencySettingsRouter
    private let interactor: IBaseCurrencySettingsInteractor

    weak var view: IBaseCurrencySettingsView?

    init(router: IBaseCurrencySettingsRouter, interactor: IBaseCurrencySettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

    private func showItems() {
        let baseCurrencyCode = interactor.baseCurrency.code

        view?.show(items: interactor.currencies.map { currency in
            CurrencyItem(code: currency.code, symbol: currency.symbol, selected: currency.code == baseCurrencyCode)
        })
    }

}

extension BaseCurrencySettingsPresenter: IBaseCurrencySettingsViewDelegate {

    func viewDidLoad() {
        showItems()
    }

    func didSelect(item: CurrencyItem) {
        if !item.selected {
            interactor.setBaseCurrency(code: item.code)
        }
        router.dismiss()
    }

}

extension BaseCurrencySettingsPresenter: IBaseCurrencySettingsInteractorDelegate {

    func didSetBaseCurrency() {
        showItems()
    }

}
