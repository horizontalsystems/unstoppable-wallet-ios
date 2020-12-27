import Foundation

struct Address {
    let raw: String
    let domain: String?
    let amount: Decimal?

    init(raw: String, domain: String? = nil, amount: Decimal? = nil) {
        self.raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        self.domain = domain?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amount = amount
    }

    var title: String {
        domain ?? raw
    }

}
