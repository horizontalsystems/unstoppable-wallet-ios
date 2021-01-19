struct Coin {
    let id: String
    let title: String
    let code: CoinCode
    let decimal: Int
    let type: CoinType
}

extension Coin: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }

}

extension Coin: Equatable {

    public static func ==(lhs: Coin, rhs: Coin) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.code == rhs.code && lhs.decimal == rhs.decimal && lhs.type == rhs.type
    }

}

extension Coin: Comparable {

    public static func <(lhs: Coin, rhs: Coin) -> Bool {
        lhs.title < rhs.title
    }

}
