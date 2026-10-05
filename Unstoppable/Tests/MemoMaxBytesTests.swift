import MarketKit
import Testing
@testable import WalletCore

// Memo limits are UTF-8 bytes, as on Android: a short Cyrillic memo can already exceed Stellar's 28
struct MemoMaxBytesTests {
    @Test(arguments: [
        (BlockchainType.bitcoin, 80),
        (.litecoin, 80),
        (.dash, 80),
        (.bitcoinCash, 220),
        (.ecash, 220),
        (.stellar, 28),
        (.ton, 120),
        (.zcash, 512),
        (.monero, 120),
        (.zano, 120),
        (.thorChain, 250),
        (.mayaChain, 250),
    ])
    func limitPerNetwork(blockchainType: BlockchainType, maxBytes: Int) {
        #expect(blockchainType.memoMaxBytes == maxBytes)
    }

    @Test func networksWithoutMemoHaveNoLimit() {
        #expect(BlockchainType.ethereum.memoMaxBytes == nil)
        #expect(BlockchainType.solana.memoMaxBytes == nil)
        #expect(BlockchainType.xrp.memoMaxBytes == nil)
    }

    @Test func stellarCountsBytesNotCharacters() {
        let limit = BlockchainType.stellar.memoMaxBytes ?? 0

        #expect("Оплата заказа 123".count == 17)
        #expect("Оплата заказа 123".utf8.count > limit)
        #expect(String(repeating: "я", count: 14).utf8.count == limit)
        #expect(String(repeating: "я", count: 15).utf8.count > limit)
    }
}
