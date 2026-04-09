import Foundation

enum Comparators {
    static func booleanFirst(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        if lhs == rhs { return .orderedSame }
        return lhs ? .orderedAscending : .orderedDescending
    }

    static func intAscending(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    static func optionalIntAscending(_ lhs: Int?, _ rhs: Int?) -> ComparisonResult {
        intAscending(lhs ?? .max, rhs ?? .max)
    }

    static func decimalDescending(_ lhs: Decimal, _ rhs: Decimal) -> ComparisonResult {
        if lhs > rhs { return .orderedAscending }
        if lhs < rhs { return .orderedDescending }
        return .orderedSame
    }

    static func optionalDecimalDescending(_ lhs: Decimal?, _ rhs: Decimal?) -> ComparisonResult {
        switch (lhs, rhs) {
        case (nil, nil): return .orderedSame
        case (nil, _): return .orderedDescending
        case (_, nil): return .orderedAscending
        case let (l?, r?): return decimalDescending(l, r)
        }
    }

    static func stringAscending(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.caseInsensitiveCompare(rhs)
    }

    static func rawStringAscending(_ lhs: String, _ rhs: String) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    static func exactMatch(_ lhs: String, _ rhs: String, filter: String) -> ComparisonResult {
        guard !filter.isEmpty else { return .orderedSame }
        return booleanFirst(
            lhs.caseInsensitiveCompare(filter) == .orderedSame,
            rhs.caseInsensitiveCompare(filter) == .orderedSame
        )
    }

    static func prefixMatch(_ lhs: String, _ rhs: String, filter: String) -> ComparisonResult {
        guard !filter.isEmpty else { return .orderedSame }
        return booleanFirst(
            lhs.range(of: filter, options: [.caseInsensitive, .anchored]) != nil,
            rhs.range(of: filter, options: [.caseInsensitive, .anchored]) != nil
        )
    }
}
