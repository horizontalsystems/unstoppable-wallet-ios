import UIKit
import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class BaseCurrencySettingsViewModel {
    private let service: BaseCurrencySettingsService

    private(set) var popularViewItems = [ViewItem]()
    private(set) var cryptoViewItems = [ViewItem]()
    private(set) var otherViewItems = [ViewItem]()

    private let disclaimerRelay = PublishRelay<String>()
    private let finishRelay = PublishRelay<Void>()

    private var currentCode: String?

    init(service: BaseCurrencySettingsService) {
        self.service = service

        let baseCurrency = service.baseCurrency

        popularViewItems = service.popularCurrencies.map { viewItem(currency: $0, selected: $0 == baseCurrency) }
        cryptoViewItems = service.cryptoCurrencies.map { viewItem(currency: $0, selected: $0 == baseCurrency) }
        otherViewItems = service.otherCurrencies.map { viewItem(currency: $0, selected: $0 == baseCurrency) }
    }

    private func viewItem(currency: Currency, selected: Bool) -> ViewItem {
        ViewItem(
                icon: CurrencyKit.Kit.currencyIcon(code: currency.code),
                code: currency.code,
                symbol: currency.symbol,
                selected: selected
        )
    }

}

extension BaseCurrencySettingsViewModel {

    var disclaimerSignal: Signal<String> {
        disclaimerRelay.asSignal()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onSelect(viewItem: ViewItem) {
        let code = viewItem.code
        let popularCurrencyCodes = service.popularCurrencies.map { $0.code }

        if popularCurrencyCodes.contains(code) {
            service.setBaseCurrency(code: code)
            finishRelay.accept(())
        } else {
            currentCode = code
            disclaimerRelay.accept(popularCurrencyCodes.joined(separator: ", "))
        }
    }

    func onAcceptDisclaimer() {
        guard let code = currentCode else {
            return
        }

        service.setBaseCurrency(code: code)
        finishRelay.accept(())
    }

}

extension BaseCurrencySettingsViewModel {

    struct ViewItem {
        let icon: UIImage?
        let code: String
        let symbol: String
        let selected: Bool
    }

}
