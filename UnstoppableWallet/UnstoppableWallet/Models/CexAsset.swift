import MarketKit

struct CexAsset {
    let id: String
    let coin: Coin?
}

extension CexAsset: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(coin)
    }

    static func ==(lhs: CexAsset, rhs: CexAsset) -> Bool {
        lhs.id == rhs.id && lhs.coin == rhs.coin
    }

}
