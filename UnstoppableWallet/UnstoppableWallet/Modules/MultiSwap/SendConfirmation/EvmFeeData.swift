import BigInt
import EvmKit
import Foundation
import MarketKit

struct EvmFeeData {
    let gasLimit: Int
    let l1Fee: BigUInt?

    init(gasLimit: Int, l1Fee: BigUInt? = nil) {
        self.gasLimit = gasLimit
        self.l1Fee = l1Fee
    }

    private func amountData(amount: Decimal, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        let coinValue = CoinValue(kind: .token(token: feeToken), value: amount)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

        return AmountData(coinValue: coinValue, currencyValue: currencyValue)
    }

    private func l1FeeValue(feeToken: Token) -> Decimal? {
        guard let l1Fee else {
            return nil
        }

        return Decimal(bigUInt: l1Fee, decimals: feeToken.decimals)
    }

    func totalAmountData(gasPrice: GasPrice?, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        guard let gasPrice else {
            return nil
        }

        var amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, feeToken.decimals)

        if let l1FeeValue = l1FeeValue(feeToken: feeToken) {
            amount += l1FeeValue
        }

        return amountData(amount: amount, feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)
    }

    func l1AmountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        l1FeeValue(feeToken: feeToken).flatMap {
            amountData(amount: $0, feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)
        }
    }

    func l2AmountData(gasPrice: GasPrice?, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        gasPrice.flatMap {
            amountData(
                amount: Decimal(gasLimit) * Decimal($0.max) / pow(10, feeToken.decimals),
                feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate
            )
        }
    }
}
