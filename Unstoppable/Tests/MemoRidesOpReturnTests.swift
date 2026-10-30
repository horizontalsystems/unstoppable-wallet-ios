import MarketKit
import Testing
@testable import WalletCore

/// A swap route memo on these chains is an OP_RETURN output, which cannot name a unified Zcash address;
/// the ZEC destination falls back to transparent there (spec 2026-10-16, as on Android memoRidesOpReturn)
struct MemoRidesOpReturnTests {
    @Test(arguments: [BlockchainType.bitcoin, .bitcoinCash, .ecash, .litecoin, .dash])
    func utxoChainsRideOpReturn(blockchainType: BlockchainType) {
        #expect(blockchainType.memoRidesOpReturn)
    }

    @Test(arguments: [BlockchainType.ethereum, .arbitrumOne, .base, .mayaChain, .thorChain, .zcash, .near, .solana, .tron, .ton, .stellar, .xrp, .monero, .zano])
    func memoCapableChainsDoNot(blockchainType: BlockchainType) {
        #expect(!blockchainType.memoRidesOpReturn)
    }

    /// the OP_RETURN chains are a subset of the public-memo chains with a short form-memo limit, so the two
    /// tables in MemoDelivery cannot drift apart
    @Test func opReturnChainsAgreeWithMemoTable() {
        for blockchainType in BlockchainType.supported where blockchainType.memoRidesOpReturn {
            #expect(blockchainType.memoType == .onChainPublic)
            #expect((blockchainType.memoMaxBytes ?? .max) <= 220)
        }
    }
}
