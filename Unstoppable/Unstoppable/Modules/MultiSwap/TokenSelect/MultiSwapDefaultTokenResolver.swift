import MarketKit

enum MultiSwapDefaultTokenResolver {
    static func `default`(for token: Token?) -> Token? {
        guard let token else {
            return nil
        }

        let marketKit = Core.shared.marketKit

        if token.type == .native { // found usd-stablecoin for selected blockchain if it's possible
            let fullCoin: FullCoin?
            switch token.blockchainType {
            case .binanceSmartChain:
                fullCoin = try? marketKit.fullCoins(coinUids: ["binance-bridged-usdt-bnb-smart-chain"]).first
            default:
                fullCoin = try? marketKit.fullCoins(coinUids: ["tether"]).first
            }
            guard
                let fullCoin,
                let defaultToken = fullCoin.tokens.first(where: { $0.blockchainType == token.blockchainType })
            else {
                return nil
            }

            return defaultToken
        }

        // return native token for all others if it's possible
        return try? marketKit.token(query: .init(blockchainType: token.blockchainType, tokenType: .native))
    }
}
