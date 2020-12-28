struct Address {
    let raw: String
    let domain: String?

    init(raw: String, domain: String? = nil) {
        self.raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        self.domain = domain?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var title: String {
        domain ?? raw
    }

}
