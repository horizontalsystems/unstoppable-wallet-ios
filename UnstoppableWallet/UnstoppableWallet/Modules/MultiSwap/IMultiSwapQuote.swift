import Foundation
import MarketKit

protocol IMultiSwapQuote {
    var amountOut: Decimal { get }
    var customButtonState: MultiSwapButtonState? { get }
    var settingsModified: Bool { get }
    func fields(tokenIn: Token, tokenOut: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField]
    func cautions() -> [CautionNew]
}
