import UIKit

protocol ISendFeeView: class {
    func set(loading: Bool)
    func set(fee: AmountInfo, convertedFee: AmountInfo?)
    func set(error: Error?)
}

protocol ISendFeeViewDelegate {
    func viewDidLoad()
}

protocol ISendFeeDelegate: class {
    var inputType: SendInputType { get }
}

protocol ISendFeeInteractor {
    var baseCurrency: Currency { get }
    func nonExpiredRateValue(coinCode: CoinCode, currencyCode: String) -> Decimal?
    func feeCoin(coin: Coin) -> Coin?
    func feeCoinProtocol(coin: Coin) -> String?
}

protocol ISendFeeModule: AnyObject {
    var delegate: ISendFeeDelegate? { get set }

    var isValid: Bool { get }

    var primaryAmountInfo: AmountInfo { get }
    var secondaryAmountInfo: AmountInfo? { get }

    func set(loading: Bool)
    func set(externalError: Error?)
    func set(fee: Decimal)
    func set(availableFeeBalance: Decimal)
    func update(inputType: SendInputType)
}
