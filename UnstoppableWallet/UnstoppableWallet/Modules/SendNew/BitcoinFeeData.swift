import BigInt
import EvmKit
import Foundation
import MarketKit

struct BitcoinFeeData {
    let fee: Decimal

    init(fee: Decimal) {
        self.fee = fee
    }

    func amountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        AmountData(kind: .token(token: feeToken), value: fee, currency: currency, rate: feeTokenRate)
    }
}
