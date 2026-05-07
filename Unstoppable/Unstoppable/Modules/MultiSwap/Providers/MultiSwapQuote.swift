import Foundation

class MultiSwapQuote {
    let expectedBuyAmount: Decimal
    let estimatedTime: TimeInterval?

    init(expectedBuyAmount: Decimal, estimatedTime: TimeInterval? = nil) {
        self.expectedBuyAmount = expectedBuyAmount
        self.estimatedTime = estimatedTime
    }

    var customButtonState: MultiSwapButtonState? {
        nil
    }

    func cautions() -> [CautionNew] {
        []
    }
}
