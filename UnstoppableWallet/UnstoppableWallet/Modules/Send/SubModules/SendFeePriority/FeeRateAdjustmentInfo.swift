import Foundation
import CurrencyKit

class FeeRateAdjustmentInfo {
    var amountInfo: SendAmountInfo
    var xRate: Decimal?
    var currency: Currency
    var balance: Decimal?

    init(amountInfo: SendAmountInfo, xRate: Decimal?, currency: Currency, balance: Decimal?) {
        self.amountInfo = amountInfo
        self.xRate = xRate
        self.currency = currency
        self.balance = balance
    }

}
