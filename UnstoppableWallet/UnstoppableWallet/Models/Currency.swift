struct Currency {
    let code: String
    let symbol: String
    let decimal: Int
}

extension Currency: Equatable {
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.code == rhs.code
    }
}

extension Currency: Identifiable {
    var id: String {
        code
    }
}
