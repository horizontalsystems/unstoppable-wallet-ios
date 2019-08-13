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
}

protocol ISendFeeModule: AnyObject {
    var delegate: ISendFeeDelegate? { get set }

    var coinValue: CoinValue { get }
    var currencyValue: CurrencyValue? { get }

    func set(fee: Decimal)
    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal)
    func update(inputType: SendInputType)
}
