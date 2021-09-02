import UIKit
import CurrencyKit
import XRatesKit
import MarketKit

protocol ISendFeeView: AnyObject {
    func set(loading: Bool)
    func set(fee: AmountInfo, convertedFee: AmountInfo?)
    func set(error: String?)
}

protocol ISendFeeViewDelegate {
    func viewDidLoad()
}

protocol ISendFeeInteractor {
    var baseCurrency: Currency { get }
    func feeCoin(platformCoin: PlatformCoin) -> PlatformCoin?
    func feeCoinProtocol(platformCoin: PlatformCoin) -> String?
    func subscribeToLatestRate(coinType: CoinType?, currencyCode: String)
    func nonExpiredRateValue(coinType: CoinType, currencyCode: String) -> Decimal?
}

protocol ISendFeeInteractorDelegate: AnyObject {
    func didReceive(latestRate: RateManagerNew.LatestRate)
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
