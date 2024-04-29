import Foundation
import MarketKit

protocol IMultiSwapConfirmationQuote {
    var amountOut: Decimal { get }
    var feeData: FeeData? { get }
    var canSwap: Bool { get }
    func cautions(baseToken: Token) -> [CautionNew]
    func priceSectionFields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField]
    func otherSections(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [[SendField]]
}
