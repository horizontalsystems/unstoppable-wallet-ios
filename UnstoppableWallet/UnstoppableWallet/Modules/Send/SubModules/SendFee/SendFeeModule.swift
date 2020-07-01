import UIKit
import CurrencyKit
import XRatesKit

protocol ISendFeeView: class {
    func set(loading: Bool)
    func set(fee: AmountInfo, convertedFee: AmountInfo?)
    func set(error: Error?)
}

protocol ISendFeeViewDelegate {
    func viewDidLoad()
}

protocol ISendFeeInteractor {
    var baseCurrency: Currency { get }
    func feeCoin(coin: Coin) -> Coin?
    func feeCoinProtocol(coin: Coin) -> String?
    func subscribeToMarketInfo(coinCode: CoinCode?, currencyCode: String)
    func nonExpiredRateValue(coinCode: String, currencyCode: String) -> Decimal?
}

protocol ISendFeeInteractorDelegate: class {
    func didReceive(marketInfo: MarketInfo)
}

protocol ISendFeeModule: AnyObject {
    var isValid: Bool { get }

    var primaryAmountInfo: AmountInfo { get }
    var secondaryAmountInfo: AmountInfo? { get }

    func set(loading: Bool)
    func set(externalError: Error?)
    func set(fee: Decimal)
    func set(availableFeeBalance: Decimal)
    func update(inputType: SendInputType)
}
