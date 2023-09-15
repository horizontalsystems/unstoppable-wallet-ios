import MarketKit

extension FullCoin: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.coin == rhs.coin && lhs.tokens == rhs.tokens
    }
}
