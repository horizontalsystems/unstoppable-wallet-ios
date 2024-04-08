import Foundation
import MarketKit

class BaseEvmMultiSwapQuote: IMultiSwapQuote {
    let allowanceState: MultiSwapAllowanceHelper.AllowanceState

    init(allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.allowanceState = allowanceState
    }

    var amountOut: Decimal {
        fatalError("Must be implemented in subclass")
    }

    var customButtonState: MultiSwapButtonState? {
        allowanceState.customButtonState
    }

    var settingsModified: Bool {
        false
    }

    func cautions() -> [CautionNew] {
        var cautions = [CautionNew]()
        cautions.append(contentsOf: allowanceState.cautions())
        return cautions
    }

    func fields(tokenIn _: Token, tokenOut _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?) -> [MultiSwapMainField] {
        var fields = [MultiSwapMainField]()
        fields.append(contentsOf: allowanceState.fields())
        return fields
    }
}
