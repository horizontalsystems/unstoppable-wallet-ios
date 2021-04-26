import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class BaseCurrencySettingsViewModel {
    private let service: BaseCurrencySettingsService

    private let finishRelay = PublishRelay<Void>()
    private(set) var popularViewItems = [ViewItem]()
    private(set) var allViewItems = [ViewItem]()

    init(service: BaseCurrencySettingsService) {
        self.service = service

        let baseCurrency = service.baseCurrency

        popularViewItems = service.popularCurrencies.map { viewItem(currency: $0, selected: $0 == baseCurrency) }
        allViewItems = service.allCurrencies.map { viewItem(currency: $0, selected: $0 == baseCurrency) }
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

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onSelect(viewItem: ViewItem) {
        service.setBaseCurrency(code: viewItem.code)
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
