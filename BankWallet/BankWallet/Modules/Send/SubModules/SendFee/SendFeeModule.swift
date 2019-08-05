import UIKit

protocol ISendFeeView: class {
    func set(fee: String?)
    func set(convertedFee: String?)
    func set(error: String?)
}

protocol ISendFeeViewDelegate {
    func onFeePriorityChange(value: Int)
    func viewDidLoad()
}

protocol ISendFeeDelegate: class {
    func updateFeeRate()
    func feeRate(priority: FeeRatePriority) -> Int
}

protocol ISendFeeInteractor {
    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
}

protocol ISendFeeModule: AnyObject {
    var delegate: ISendFeeDelegate? { get set }

    var coinFee: CoinValue { get }
    var fiatFee: CurrencyValue? { get }

    var feeRatePriority: FeeRatePriority { get }
    var feeRate: Int { get }
    var validState: Bool { get }

    func update(fee: Decimal)
    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal)
    func update(sendInputType: SendInputType)
}
