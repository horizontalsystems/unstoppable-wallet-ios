import Foundation
import StellarKit

/// One route of a quote round. `id` is the venue id the backend served it under and is handed back to
/// the provider for the preview; `venue` is the synced provider row (or a placeholder for an unknown id).
public class MultiSwapQuote {
    public let id: String
    public let venue: SwapVenue
    public let expectedBuyAmount: Decimal
    public let estimatedTime: TimeInterval?
    /// Which Zcash addresses this route takes (present when ZEC is on either side)
    public let zcashAddressRules: USwapMultiSwapApi.ZcashAddressRules?
    /// Present only when the route has an AML address precheck
    public let amlProviderId: String?
    /// Set when the buy token is a Stellar classic asset the account holds no trustline for
    var activationAsset: StellarKit.Asset?

    public init(
        id: String,
        venue: SwapVenue,
        expectedBuyAmount: Decimal,
        estimatedTime: TimeInterval? = nil,
        zcashAddressRules: USwapMultiSwapApi.ZcashAddressRules? = nil,
        amlProviderId: String? = nil
    ) {
        self.id = id
        self.venue = venue
        self.expectedBuyAmount = expectedBuyAmount
        self.estimatedTime = estimatedTime
        self.zcashAddressRules = zcashAddressRules
        self.amlProviderId = amlProviderId
    }

    var customButtonState: MultiSwapButtonState? {
        activationAsset.map { StellarActivationHelper.buttonState(asset: $0) }
    }

    func cautions() -> [CautionNew] {
        []
    }
}
