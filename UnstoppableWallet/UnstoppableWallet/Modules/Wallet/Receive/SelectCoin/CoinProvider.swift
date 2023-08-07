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
                    !fullCoin.eligibleTokens(accountType: accountType).isEmpty
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
            let queries = blockchainTypes.map { TokenQuery(blockchainType: $0, tokenType: .native) }
            let nativeTokens = try marketKit.tokens(queries: queries)
            return nativeTokens.map { $0.coin }
        } catch {
            return []
        }
    }

}
