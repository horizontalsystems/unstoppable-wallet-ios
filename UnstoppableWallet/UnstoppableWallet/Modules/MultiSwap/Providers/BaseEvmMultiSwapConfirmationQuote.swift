import Foundation
import MarketKit

class BaseEvmMultiSwapConfirmationQuote: BaseSendEvmData, IMultiSwapConfirmationQuote {
    var amountOut: Decimal {
        fatalError("Must be implemented in subclass")
    }

    var feeData: FeeData? {
        evmFeeData.map { .evm(evmFeeData: $0) }
    }

    var canSwap: Bool {
        gasPrice != nil && evmFeeData != nil
    }

    func cautions(baseToken _: Token) -> [CautionNew] {
        []
    }

    func fields(tokenIn _: Token, tokenOut _: Token, baseToken: Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let nonce {
            fields.append(
                .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
            )
        }

        fields.append(contentsOf: feeFields(feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
