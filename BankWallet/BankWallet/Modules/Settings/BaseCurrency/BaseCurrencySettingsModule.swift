struct CurrencyItem: Equatable {
    let code: String
    let symbol: String
    let selected: Bool

    static func ==(lhs: CurrencyItem, rhs: CurrencyItem) -> Bool {
        return lhs.code == rhs.code
    }
}

protocol IBaseCurrencySettingsView: class {
    func show(items: [CurrencyItem])
}

protocol IBaseCurrencySettingsViewDelegate {
    func viewDidLoad()
    func didSelect(item: CurrencyItem)
}

protocol IBaseCurrencySettingsInteractor {
    var currencies: [Currency] { get }
    var baseCurrency: Currency { get }
    func setBaseCurrency(code: String)
}

protocol IBaseCurrencySettingsInteractorDelegate: class {
    func didSetBaseCurrency()
}

protocol IBaseCurrencySettingsRouter {
    func dismiss()
}
