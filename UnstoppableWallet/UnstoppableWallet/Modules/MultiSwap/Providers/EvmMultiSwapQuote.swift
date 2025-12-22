import Foundation

class EvmMultiSwapQuote: MultiSwapQuote {
    let allowanceState: MultiSwapAllowanceHelper.AllowanceState

    init(expectedBuyAmount: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.allowanceState = allowanceState

        super.init(expectedBuyAmount: expectedBuyAmount)
    }

    override var customButtonState: MultiSwapButtonState? {
        allowanceState.customButtonState
    }

    override func cautions() -> [CautionNew] {
        allowanceState.cautions()
    }
}
