import Foundation
import HsToolKit
import MarketKit
import Testing
@testable import WalletCore

// Cross Pay pays out on the recipient's chain, and some chains are never a supported recipient: the pair
// is refused before the provider's asset map is read. Pairs the map decides need the real repository
// and are checked by hand.
struct CrossPayServiceSupportTests {
    @Test func xrpRecipientIsNotSupported() {
        #expect(!Self.service().supports(tokenIn: Self.token(.bitcoin), tokenOut: Self.token(.xrp)))
    }

    @Test func stellarRecipientIsNotSupported() {
        #expect(!Self.service().supports(tokenIn: Self.token(.bitcoin), tokenOut: Self.token(.stellar)))
    }
}

extension CrossPayServiceSupportTests {
    private static func service() -> CrossPayService {
        CrossPayService(
            api: USwapMultiSwapApi(baseURL: URL(string: "https://example.invalid")!, apiKey: nil, networkManager: NetworkManager()),
            // never reached for these recipients: the refusal comes first
            assetRepository: { _ in fatalError("the asset map must not be read") },
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: CrossPayService.providerId)
        )
    }

    private static func token(_ blockchainType: BlockchainType) -> Token {
        Token(
            coin: Coin(uid: blockchainType.uid, name: blockchainType.uid, code: blockchainType.uid),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: .native,
            decimals: 8
        )
    }
}
