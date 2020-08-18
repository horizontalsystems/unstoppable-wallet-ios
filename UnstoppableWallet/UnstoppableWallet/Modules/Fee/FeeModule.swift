import CurrencyKit
import XRatesKit

protocol IFeeInteractor {
    var baseCurrency: Currency { get }
    func feeCoin(coin: Coin) -> Coin?
    func feeCoinProtocol(coin: Coin) -> String?
    func nonExpiredRateValue(coinCode: String, currencyCode: String) -> Decimal?
}

protocol IFeeModule: AnyObject {
    func viewItem(coin: Coin, fee: Decimal, reversed: Bool) -> FeeViewItem
    func coinValue(coin: Coin, fee: Decimal) -> CoinValue
}

protocol IFeeViewItemFactory {
    func viewItem(coinValue: CoinValue, currencyValue: CurrencyValue?, reversed: Bool) -> FeeViewItem
}

struct FeeViewItem {
    let value: String?
}

class FeeModule {

    static func module() -> IFeeModule {
        let factory = FeeViewItemFactory()

        let interactor = FeeInteractor(rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, feeCoinProvider: App.shared.feeCoinProvider)
        let presenter = FeePresenter(interactor: interactor, factory: factory)

        return presenter
    }

}
