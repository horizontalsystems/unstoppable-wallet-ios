import Foundation
import CurrencyKit

class SendFeeInteractor {
    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    private let feeCoinProvider: IFeeCoinProvider

    init(rateManager: IRateManager, currencyKit: ICurrencyKit, feeCoinProvider: IFeeCoinProvider) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.feeCoinProvider = feeCoinProvider
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    func feeCoin(coin: Coin) -> Coin? {
        feeCoinProvider.feeCoin(coin: coin)
    }

    func feeCoinProtocol(coin: Coin) -> String? {
        feeCoinProvider.feeCoinProtocol(coin: coin)
    }

}
