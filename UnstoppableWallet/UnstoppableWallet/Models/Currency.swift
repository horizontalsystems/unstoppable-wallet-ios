public struct Currency {
    public let code: String
    public let symbol: String
    public let decimal: Int
}

extension Currency: Equatable {
    public static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.code == rhs.code
    }
}
