import MarketKit
import Testing
@testable import WalletCore

struct CoinSyntheticTests {
    @Test func originalCoinIsNotSynthetic() {
        let coin = Coin(uid: "bitcoin", name: "Bitcoin", code: "BTC", coinGeckoId: "bitcoin")
        #expect(coin.isSynthetic == false)
    }

    @Test func reListedCoinIsSynthetic() {
        let coin = Coin(uid: "thorchain-secured-bitcoin", name: "Bitcoin (THORChain)", code: "BTC", coinGeckoId: "bitcoin")
        #expect(coin.isSynthetic == true)
    }

    @Test func coinWithoutCoinGeckoIdIsNotSynthetic() {
        let coin = Coin(uid: "custom-coin", name: "Custom", code: "CST", coinGeckoId: nil)
        #expect(coin.isSynthetic == false)
    }
}
