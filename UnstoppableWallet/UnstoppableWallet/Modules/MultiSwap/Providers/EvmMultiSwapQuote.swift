import Foundation

class EvmMultiSwapQuote: MultiSwapQuote {
    let allowanceState: MultiSwapAllowanceHelper.AllowanceState

    init(expectedBuyAmount: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState, estimatedTime: TimeInterval? = nil) {
        self.allowanceState = allowanceState

        super.init(expectedBuyAmount: expectedBuyAmount, estimatedTime: estimatedTime)
    }

    override var customButtonState: MultiSwapButtonState? {
        allowanceState.customButtonState
    }

    override func cautions() -> [CautionNew] {
        allowanceState.cautions()
    }
}
