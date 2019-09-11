protocol IBaseCurrencySettingsView: class {
    func show(viewItems: [CurrencyViewItem])
}

protocol IBaseCurrencySettingsViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IBaseCurrencySettingsInteractor: AnyObject {
    var baseCurrency: Currency { get set }
    var currencies: [Currency] { get }
}

protocol IBaseCurrencySettingsRouter {
    func dismiss()
}

struct CurrencyViewItem {
    let code: String
    let symbol: String
    let selected: Bool
}
