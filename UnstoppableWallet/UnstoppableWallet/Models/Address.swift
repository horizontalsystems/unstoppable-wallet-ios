struct Address: Equatable {
    let raw: String
    let domain: String?

    init(raw: String, domain: String? = nil) {
        self.raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        self.domain = domain?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var title: String {
        domain ?? raw
    }

    static func ==(lhs: Address, rhs: Address) -> Bool {
        lhs.raw == rhs.raw &&
        lhs.domain == rhs.domain
    }

}
