import Foundation
import MarketKit

class CoinProvider {
    private let marketKit: MarketKit.Kit
    private let accountType: AccountType

    var filter: String = ""
    let predefined: [FullCoin]

    init(marketKit: MarketKit.Kit, accountType: AccountType, predefined: [FullCoin]) {
        self.marketKit = marketKit
        self.accountType = accountType
        self.predefined = predefined
    }

}

extension CoinProvider {

    func fetch() -> [FullCoin] {
        do {
            if !filter.isEmpty {
                let fullCoins = try marketKit.fullCoins(filter: filter)

                return fullCoins.filter { fullCoin in
                    fullCoin.tokens.contains { accountType.supports(token: $0) }
                }
            } else {
                return predefined
            }
        } catch {
            return []
        }
    }

}

extension CoinProvider {

    static func nativeCoins(marketKit: MarketKit.Kit) -> [Coin] {
        do {
            let blockchainTypes = BlockchainType.supported.sorted()
            let queries = blockchainTypes.map { $0.nativeTokenQueries }.flatMap { $0 }
            let nativeTokens = try marketKit.tokens(queries: queries)
            return nativeTokens.map { $0.coin }
        } catch {
            return []
        }
    }

}
