enum PriceChangeMode: String, CaseIterable, Codable {
    case hour24 = "hour_24"
    case day1 = "day_1"
}

extension PriceChangeMode {
    var statName: String {
        switch self {
        case .hour24: return "hour_24"
        case .day1: return "day_1"
        }
    }
}
