enum PriceChangeMode: String, CaseIterable, Codable {
    case hour24 = "hour_24"
    case midnightUtc = "midnight_utc"
}

extension PriceChangeMode {
    var statName: String {
        switch self {
        case .hour24: return "hour_24"
        case .midnightUtc: return "midnight_utc"
        }
    }
}
