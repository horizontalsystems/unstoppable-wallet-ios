import Foundation
import StellarKit

public class MultiSwapQuote {
    public let expectedBuyAmount: Decimal
    public let estimatedTime: TimeInterval?
    // Set when the buy token is a Stellar classic asset the account holds no trustline for
    var activationAsset: StellarKit.Asset?

    public init(expectedBuyAmount: Decimal, estimatedTime: TimeInterval? = nil) {
        self.expectedBuyAmount = expectedBuyAmount
        self.estimatedTime = estimatedTime
    }

    var customButtonState: MultiSwapButtonState? {
        activationAsset.map { StellarActivationHelper.buttonState(asset: $0) }
    }

    func cautions() -> [CautionNew] {
        []
    }
}
