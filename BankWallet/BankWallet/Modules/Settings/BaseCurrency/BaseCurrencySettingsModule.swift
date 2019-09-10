protocol IBaseCurrencySettingsView: class {
    func show(viewItems: [CurrencyViewItem])
}

protocol IBaseCurrencySettingsViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IBaseCurrencySettingsInteractor {
    var currencies: [Currency] { get }
    var baseCurrency: Currency { get }
    func set(baseCurrency: Currency)
}

protocol IBaseCurrencySettingsRouter {
    func dismiss()
}

struct CurrencyViewItem {
    let code: String
    let symbol: String
    let selected: Bool
}
