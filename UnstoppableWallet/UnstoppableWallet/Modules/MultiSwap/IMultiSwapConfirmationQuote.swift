import Foundation
import MarketKit

protocol IMultiSwapConfirmationQuote {
    var amountOut: Decimal { get }
    var feeData: FeeData? { get }
    var canSwap: Bool { get }
    func cautions(feeToken: Token?) -> [CautionNew]
    func priceSectionFields(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField]
    func otherSections(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [[SendConfirmField]]
}
