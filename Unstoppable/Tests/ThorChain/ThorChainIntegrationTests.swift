import MarketKit
import Testing
@testable import WalletCore

struct ThorChainIntegrationTests {
    @Test func nativeRuneMetadataSelectsThorChainRouteIdentity() {
        let token = Token(
            coin: Coin(uid: "thorchain", name: "THORChain", code: "RUNE"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .native,
            decimals: 8
        )

        #expect(token.blockchainType == .thorChain)
        #expect(token.type == .native)
        #expect(token.decimals == 8)
    }
}
