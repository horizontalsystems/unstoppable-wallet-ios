struct Coin {
    let title: String
    let code: CoinCode
    let decimal: Int
    let type: CoinType
}

extension Coin: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        // todo: add "type" to hash
    }

}

extension Coin: Equatable {

    public static func ==(lhs: Coin, rhs: Coin) -> Bool {
        return lhs.title == rhs.title && lhs.code == rhs.code && lhs.decimal == rhs.decimal && lhs.type == rhs.type
    }

}

extension Coin: Comparable {

    public static func <(lhs: Coin, rhs: Coin) -> Bool {
        return lhs.title < rhs.title
    }

}
