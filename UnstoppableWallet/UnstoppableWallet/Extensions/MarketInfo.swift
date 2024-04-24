import MarketKit

extension MarketInfo: Hashable {
    public static func == (lhs: MarketInfo, rhs: MarketInfo) -> Bool {
        lhs.fullCoin.coin.uid == rhs.fullCoin.coin.uid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fullCoin.coin.uid)
    }
}
