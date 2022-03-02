import RxSwift
import RxRelay
import MarketKit

class CoinManager {
    private let featuredCoinUids: [String] = [
        "bitcoin",
        "ethereum",
        "binancecoin",
        "matic-network",
        "zcash",
        "dash",
        "litecoin",
        "bitcoin-cash",
        "uniswap",
        "sushi",
        "pancakeswap-token",
        "havven",
        "1inch",
        "curve-dao-token",
        "0x",
        "bancor",
        "balancer",
        "republic-protocol",
        "tether",
        "usd-coin",
        "binance-usd",
        "dai",
        "aave",
        "maker",
        "compound-governance-token",
        "yearn-finance",
        "badger-dao",
        "chainlink"
    ]

    private let marketKit: Kit
    private let storage: ICustomTokenStorage

    init(marketKit: Kit, storage: ICustomTokenStorage) {
        self.marketKit = marketKit
        self.storage = storage
    }

    private func customFullCoins(customTokens: [CustomToken]) -> [FullCoin] {
        let platformCoins = customTokens.map { $0.platformCoin }
        let dictionary = Dictionary(grouping: platformCoins, by: { $0.coin })

        return dictionary.map { coin, platformCoins in
            FullCoin(coin: coin, platforms: platformCoins.map { $0.platform })
        }
    }

    private func adjustedCustomTokens(customTokens: [CustomToken]) throws -> [CustomToken] {
        let existingPlatformCoins = try marketKit.platformCoins(coinTypes: customTokens.map { $0.coinType })
        return customTokens.filter { customToken in !existingPlatformCoins.contains { $0.coinType == customToken.coinType } }
    }

    private func customFullCoins(filter: String) throws -> [FullCoin] {
        let customTokens = storage.customTokens(filter: filter)
        let adjustedCustomTokens = try adjustedCustomTokens(customTokens: customTokens)
        return customFullCoins(customTokens: adjustedCustomTokens)
    }

    private func customFullCoins(coinTypes: [CoinType]) throws -> [FullCoin] {
        let customTokens = storage.customTokens(coinTypeIds: coinTypes.map { $0.id })
        let adjustedCustomTokens = try adjustedCustomTokens(customTokens: customTokens)
        return customFullCoins(customTokens: adjustedCustomTokens)
    }

    private func customPlatformCoins(platformType: PlatformType, filter: String) throws -> [PlatformCoin] {
        let customTokens = storage.customTokens(platformType: platformType, filter: filter)
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

    func featuredFullCoins(enabledPlatformCoins: [PlatformCoin]) throws -> [FullCoin] {
        let appFullCoins = try customFullCoins(coinTypes: enabledPlatformCoins.map { $0.coinType })
        let kitFullCoins = try marketKit.fullCoins(coinUids: featuredCoinUids + enabledPlatformCoins.map { $0.coin.uid })

        return appFullCoins + kitFullCoins
    }

    func fullCoin(coinUid: String) throws -> FullCoin? {
        try marketKit.fullCoins(coinUids: [coinUid]).first
    }

    func fullCoins(filter: String = "", limit: Int = 20) throws -> [FullCoin] {
        let appFullCoins = try customFullCoins(filter: filter)
        let kitFullCoins = try marketKit.fullCoins(filter: filter, limit: limit)

        return appFullCoins + kitFullCoins
    }

    func fullCoins(coinUids: [String]) throws -> [FullCoin] {
        try marketKit.fullCoins(coinUids: coinUids)
    }

    func platformCoin(coinType: CoinType) throws -> PlatformCoin? {
        try marketKit.platformCoin(coinType: coinType) ?? customPlatformCoin(coinType: coinType)
    }

    func platformCoins(platformType: PlatformType, filter: String, limit: Int = 20) throws -> [PlatformCoin] {
        try marketKit.platformCoins(platformType: platformType, filter: filter, limit: limit) + customPlatformCoins(platformType: platformType, filter: filter)
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
