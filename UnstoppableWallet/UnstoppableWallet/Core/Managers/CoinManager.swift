import RxSwift
import RxRelay
import MarketKit

class CoinManager {
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

    private func customFullCoins(filter: String) throws -> [FullCoin] {
        let customTokens = storage.customTokens(filter: filter)
        return try adjustedCustomTokens(customTokens: customTokens).map { $0.platformCoin.fullCoin }
    }

    private func customFullCoins(coinTypes: [CoinType]) throws -> [FullCoin] {
        let customTokens = storage.customTokens(coinTypeIds: coinTypes.map { $0.id })
        return try adjustedCustomTokens(customTokens: customTokens).map { $0.platformCoin.fullCoin }
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

extension CoinManager {

    func featuredFullCoins(enabledCoinTypes: [CoinType]) throws -> [FullCoin] {
        let appFullCoins = try customFullCoins(coinTypes: enabledCoinTypes)
        let kitFullCoins = try marketKit.fullCoins(coinTypes: featuredCoinTypes + enabledCoinTypes)

        return appFullCoins + kitFullCoins
    }

    func fullCoins(filter: String = "", limit: Int = 20) throws -> [FullCoin] {
        let appFullCoins = try customFullCoins(filter: filter)
        let kitFullCoins = try marketKit.fullCoins(filter: filter, limit: limit)

        return appFullCoins + kitFullCoins
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
