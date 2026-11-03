import Foundation

class EvmMultiSwapQuote: MultiSwapQuote {
    let allowanceState: MultiSwapAllowanceHelper.AllowanceState

    init(
        id: String,
        venue: SwapVenue,
        expectedBuyAmount: Decimal,
        allowanceState: MultiSwapAllowanceHelper.AllowanceState,
        estimatedTime: TimeInterval? = nil,
        zcashAddressRules: USwapMultiSwapApi.ZcashAddressRules? = nil,
        amlProviderId: String? = nil
    ) {
        self.allowanceState = allowanceState

        super.init(
            id: id,
            venue: venue,
            expectedBuyAmount: expectedBuyAmount,
            estimatedTime: estimatedTime,
            zcashAddressRules: zcashAddressRules,
            amlProviderId: amlProviderId
        )
    }

    override var customButtonState: MultiSwapButtonState? {
        super.customButtonState ?? allowanceState.customButtonState
    }

    override func cautions() -> [CautionNew] {
        allowanceState.cautions()
    }
}
