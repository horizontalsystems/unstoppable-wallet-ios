struct Coin {
    let title: String
    let code: CoinCode
    let type: CoinType
}

extension Coin: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

}

extension Coin: Equatable {

    public static func ==(lhs: Coin, rhs: Coin) -> Bool {
        return lhs.code == rhs.code && lhs.title == rhs.title && lhs.type == rhs.type
    }

}

extension Coin: Comparable {

    public static func <(lhs: Coin, rhs: Coin) -> Bool {
        return lhs.title < rhs.title
    }

}
