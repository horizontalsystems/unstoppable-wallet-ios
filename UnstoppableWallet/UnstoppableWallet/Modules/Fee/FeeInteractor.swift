import Foundation
import CurrencyKit
import RxSwift

class FeeInteractor {
    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    private let feeCoinProvider: IFeeCoinProvider

    init(rateManager: IRateManager, currencyKit: ICurrencyKit, feeCoinProvider: IFeeCoinProvider) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.feeCoinProvider = feeCoinProvider
    }

}

extension FeeInteractor: IFeeInteractor {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    func feeCoin(coin: Coin) -> Coin? {
        feeCoinProvider.feeCoin(coin: coin)
    }

    func feeCoinProtocol(coin: Coin) -> String? {
        feeCoinProvider.feeCoinProtocol(coin: coin)
    }

    func nonExpiredRateValue(coinCode: String, currencyCode: String) -> Decimal? {
        guard let marketInfo = rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode), !marketInfo.expired else {
            return nil
        }
        return marketInfo.rate
    }

}
