import Foundation
import MarketKit
import Testing
@testable import WalletCore

/// Cross Pay pays out on the recipient's chain, and some chains are never a supported recipient: the pair
/// is refused before the catalog is read. Pairs the catalog decides need the real catalog and are checked
/// by hand.
struct CrossPayServiceSupportTests {
    @Test func xrpRecipientIsNotSupported() {
        #expect(!CrossPayService.supportsRecipientChain(.xrp))
    }

    @Test func stellarRecipientIsNotSupported() {
        #expect(!CrossPayService.supportsRecipientChain(.stellar))
    }

    @Test func ordinaryRecipientChainsAreSupported() {
        #expect(CrossPayService.supportsRecipientChain(.bitcoin))
        #expect(CrossPayService.supportsRecipientChain(.ethereum))
    }
}
