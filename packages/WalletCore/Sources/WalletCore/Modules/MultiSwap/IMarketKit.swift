import MarketKit

protocol IMarketKit {
    func token(query: TokenQuery) throws -> Token?
    func fullCoins(coinUids: [String]) throws -> [FullCoin]
    func tokens(queries: [TokenQuery]) throws -> [Token]
}

extension MarketKit.Kit: IMarketKit {}
