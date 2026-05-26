public struct Currency: Hashable {
    public let code: String
    public let symbol: String
    public let decimal: Int

    public init(code: String, symbol: String, decimal: Int) {
        self.code = code
        self.symbol = symbol
        self.decimal = decimal
    }
}
