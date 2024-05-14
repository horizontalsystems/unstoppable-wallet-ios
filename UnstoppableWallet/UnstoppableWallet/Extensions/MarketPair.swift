import MarketKit

extension MarketPair: Hashable {
    public static func == (lhs: MarketPair, rhs: MarketPair) -> Bool {
        lhs.base == rhs.base && lhs.target == rhs.target && lhs.marketName == rhs.marketName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(target)
        hasher.combine(marketName)
    }
}
