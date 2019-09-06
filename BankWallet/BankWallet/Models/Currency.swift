struct Currency {
    let code: String
    let symbol: String
    let decimal: Int
}

extension Currency: Equatable {
    public static func ==(lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code
    }
}
