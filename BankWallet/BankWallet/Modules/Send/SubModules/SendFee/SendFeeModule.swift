import UIKit

protocol ISendFeeView: class {
    func set(fee: AmountInfo, convertedFee: AmountInfo?)
    func set(duration: TimeInterval?)
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
    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
    func feeCoin(coin: Coin) -> Coin?
    func feeCoinProtocol(coin: Coin) -> String?
}

protocol ISendFeeModule: AnyObject {
    var delegate: ISendFeeDelegate? { get set }

    var isValid: Bool { get }

    var primaryAmountInfo: AmountInfo { get }
    var secondaryAmountInfo: AmountInfo? { get }

    func set(fee: Decimal)
    func set(availableFeeBalance: Decimal)
    func set(duration: TimeInterval)
    func update(inputType: SendInputType)
}
