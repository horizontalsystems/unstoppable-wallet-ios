import Foundation
import CurrencyKit
import XRatesKit

class FeePresenter {
    private let interactor: IFeeInteractor
    private let factory: IFeeViewItemFactory

    init(interactor: IFeeInteractor, factory: IFeeViewItemFactory) {
        self.interactor = interactor
        self.factory = factory
    }

}

extension FeePresenter: IFeeModule {

    func viewItem(coin: Coin, fee: Decimal, reversed: Bool) -> FeeViewItem {
        factory.viewItem(coinValue: coinValue(coin: coin, fee: fee), currencyValue: currencyValue(coin: coin, fee: fee), reversed: reversed)
    }

    func coinValue(coin: Coin, fee: Decimal) -> CoinValue {
        let feeCoin = interactor.feeCoin(coin: coin) ?? coin

        return CoinValue(coin: feeCoin, value: fee)
    }

    func currencyValue(coin: Coin, fee: Decimal) -> CurrencyValue? {
        let baseCurrency = interactor.baseCurrency
        let rate = interactor.nonExpiredRateValue(coinCode: coin.code, currencyCode: baseCurrency.code)

        return rate.map { CurrencyValue(currency: baseCurrency, value: $0 * fee) }
    }

}
