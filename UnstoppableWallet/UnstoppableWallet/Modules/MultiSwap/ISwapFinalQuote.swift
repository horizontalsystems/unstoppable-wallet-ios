import Foundation
import MarketKit

protocol ISwapFinalQuote {
    var amountOut: Decimal { get }
    var feeData: FeeData? { get }
    var canSwap: Bool { get }
    func cautions(baseToken: Token) -> [CautionNew]
    func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField]
}
