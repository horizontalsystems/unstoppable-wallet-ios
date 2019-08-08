import UIKit

protocol ISendFeeView: class {
    func set(fee: String?)
    func set(convertedFee: String?)
    func set(error: String?)
}

protocol ISendFeeViewDelegate {
    func viewDidLoad()
}

protocol ISendFeeDelegate: class {
}

protocol ISendFeeInteractor {
    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
}

protocol ISendFeeModule: AnyObject {
    var delegate: ISendFeeDelegate? { get set }

    var coinFee: CoinValue { get }
    var fiatFee: CurrencyValue? { get }

    func set(fee: Decimal)
    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal)
    func update(sendInputType: SendInputType)
}
