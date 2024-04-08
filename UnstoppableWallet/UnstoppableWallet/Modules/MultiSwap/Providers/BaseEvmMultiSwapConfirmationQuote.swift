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

    func cautions(feeToken _: Token?) -> [CautionNew] {
        []
    }

    func priceSectionFields(tokenIn _: Token, tokenOut _: Token, feeToken _: Token?, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate _: Decimal?) -> [SendConfirmField] {
        []
    }

    func otherSections(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [[SendConfirmField]] {
        var sections = [[SendConfirmField]]()

        if let nonce {
            sections.append(
                [
                    .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
                ]
            )
        }

        if let feeToken {
            let additionalFeeFields = additionalFeeFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)
            sections.append(feeFields(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate) + additionalFeeFields)
        }

        return sections
    }

    func additionalFeeFields(tokenIn _: Token, tokenOut _: Token, feeToken _: Token?, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate _: Decimal?) -> [SendConfirmField] {
        []
    }
}
