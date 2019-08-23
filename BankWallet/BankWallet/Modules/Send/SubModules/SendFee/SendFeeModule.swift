import UIKit

protocol ISendFeeView: class {
    func set(fee: AmountInfo?)
    func set(convertedFee: AmountInfo?)
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

    var coinValue: CoinValue { get }
    var currencyValue: CurrencyValue? { get }

    func set(fee: Decimal)
    func set(availableFeeBalance: Decimal)
    func update(inputType: SendInputType)
}
