import Foundation

class MultiSwapQuote {
    let expectedBuyAmount: Decimal

    init(expectedBuyAmount: Decimal) {
        self.expectedBuyAmount = expectedBuyAmount
    }

    var customButtonState: MultiSwapButtonState? {
        nil
    }

    func cautions() -> [CautionNew] {
        []
    }
}
