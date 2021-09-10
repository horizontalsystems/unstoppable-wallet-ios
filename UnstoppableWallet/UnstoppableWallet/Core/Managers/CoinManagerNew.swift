import RxSwift
import RxRelay
import MarketKit

class CoinManagerNew {
    private let featuredCoinTypes: [CoinType] = [.bitcoin, .ethereum, .binanceSmartChain]

    private let marketKit: Kit
    private let storage: ICustomTokenStorage

    init(marketKit: Kit, storage: ICustomTokenStorage) {
        self.marketKit = marketKit
        self.storage = storage
    }

    private func adjustedCustomTokens(customTokens: [CustomToken]) throws -> [CustomToken] {
        let existingPlatformCoins = try marketKit.platformCoins(coinTypes: customTokens.map { $0.coinType })
        return customTokens.filter { customToken in !existingPlatformCoins.contains { $0.coinType == customToken.coinType } }
    }

    private func customMarketCoins(filter: String) throws -> [MarketCoin] {
        let customTokens = storage.customTokens(filter: filter)
        return try adjustedCustomTokens(customTokens: customTokens).map { $0.platformCoin.marketCoin }
    }

    private func customMarketCoins(coinTypes: [CoinType]) throws -> [MarketCoin] {
        let customTokens = storage.customTokens(coinTypeIds: coinTypes.map { $0.id })
        return try adjustedCustomTokens(customTokens: customTokens).map { $0.platformCoin.marketCoin }
    }

    private func customPlatformCoins() throws -> [PlatformCoin] {
        let customTokens = storage.customTokens()
        return try adjustedCustomTokens(customTokens: customTokens).map { $0.platformCoin }
    }

    private func customPlatformCoins(coinTypeIds: [String]) throws -> [PlatformCoin] {
        let customTokens = storage.customTokens(coinTypeIds: coinTypeIds)
        return try adjustedCustomTokens(customTokens: customTokens).map { $0.platformCoin }
    }

    private func customPlatformCoin(coinType: CoinType) -> PlatformCoin? {
        storage.customToken(coinType: coinType).map { $0.platformCoin }
    }

}

extension CoinManagerNew {

    func featuredMarketCoins(enabledCoinTypes: [CoinType]) throws -> [MarketCoin] {
        let appMarketCoins = try customMarketCoins(coinTypes: enabledCoinTypes)
        let kitMarketCoins = try marketKit.marketCoins(coinTypes: featuredCoinTypes + enabledCoinTypes)

        return appMarketCoins + kitMarketCoins
    }

    func marketCoins(filter: String = "", limit: Int = 20) throws -> [MarketCoin] {
        let appMarketCoins = try customMarketCoins(filter: filter)
        let kitMarketCoins = try marketKit.marketCoins(filter: filter, limit: limit)

        return appMarketCoins + kitMarketCoins
    }

    func platformCoin(coinType: CoinType) throws -> PlatformCoin? {
        try marketKit.platformCoin(coinType: coinType) ?? customPlatformCoin(coinType: coinType)
    }

    func platformCoins() throws -> [PlatformCoin] {
        try marketKit.platformCoins() + customPlatformCoins()
    }

    func platformCoins(coinTypes: [CoinType]) throws -> [PlatformCoin] {
        try marketKit.platformCoins(coinTypes: coinTypes)
    }

    func platformCoins(coinTypeIds: [String]) throws -> [PlatformCoin] {
        let kitPlatformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds)
        let appPlatformCoins = try customPlatformCoins(coinTypeIds: coinTypeIds)

        return kitPlatformCoins + appPlatformCoins
    }

    func save(customTokens: [CustomToken]) {
        storage.save(customTokens: customTokens)
    }

}
