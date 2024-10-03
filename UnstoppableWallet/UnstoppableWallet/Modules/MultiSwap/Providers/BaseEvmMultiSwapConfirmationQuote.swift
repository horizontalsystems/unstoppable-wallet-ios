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

    func priceSectionFields(tokenIn _: Token, tokenOut _: Token, baseToken _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate _: Decimal?) -> [TransactionField] {
        []
    }

    func otherSections(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [[TransactionField]] {
        var sections = [[TransactionField]]()

        if let nonce {
            sections.append(
                [
                    .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
                ]
            )
        }

        let additionalFeeFields = additionalFeeFields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)
        sections.append(feeFields(feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate) + additionalFeeFields)

        return sections
    }

    func additionalFeeFields(tokenIn _: Token, tokenOut _: Token, baseToken _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate _: Decimal?) -> [TransactionField] {
        []
    }
}
