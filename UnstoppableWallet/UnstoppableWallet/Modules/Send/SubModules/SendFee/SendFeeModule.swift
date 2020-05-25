import UIKit
import CurrencyKit

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
}

protocol ISendFeeModule: AnyObject {
    var isValid: Bool { get }

    var primaryAmountInfo: AmountInfo { get }
    var secondaryAmountInfo: AmountInfo? { get }

    func set(loading: Bool)
    func set(externalError: Error?)
    func set(fee: Decimal)
    func set(availableFeeBalance: Decimal)
    func set(rateValue: Decimal?)
    func update(inputType: SendInputType)
}
