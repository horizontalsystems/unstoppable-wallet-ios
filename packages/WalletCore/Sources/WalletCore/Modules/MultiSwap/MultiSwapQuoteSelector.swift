import Foundation

/// What the selector needs from a quote: its identity on the screen and the two values it ranks by.
protocol QuoteLike {
    var key: String { get }
    var expectedBuyAmount: Decimal { get }
    var estimatedTime: TimeInterval? { get }
}

/// Pure quote ranking and selection for the swap screen, shared by the Standard and the Private tab.
enum MultiSwapQuoteSelector {
    /// One quote per key: two routes with the same key keep the higher amount (logged; the backend
    /// returns one route per venue, so a duplicate is a server quirk, not a choice to offer).
    static func dedupe<Q: QuoteLike>(_ quotes: [Q]) -> [Q] {
        var byKey = [String: Int]()
        var result = [Q]()

        for quote in quotes {
            if let index = byKey[quote.key] {
                print("[MultiSwapQuoteSelector] duplicate quote for \(quote.key)")

                if quote.expectedBuyAmount > result[index].expectedBuyAmount {
                    result[index] = quote
                }
            } else {
                byKey[quote.key] = result.count
                result.append(quote)
            }
        }

        return result
    }

    static func best<Q: QuoteLike>(_ quotes: [Q]) -> Q? {
        quotes.max { $0.expectedBuyAmount < $1.expectedBuyAmount }
    }

    /// The user's pick while it is still quoted, the best quote otherwise.
    static func current<Q: QuoteLike>(quotes: [Q], userSelectedKey: String?, best: Q?) -> Q? {
        guard let userSelectedKey else {
            return best
        }

        return quotes.first { $0.key == userSelectedKey } ?? best
    }

    static func sorted<Q: QuoteLike>(_ quotes: [Q], by sortType: MultiSwapViewModel.QuoteSortType) -> [Q] {
        switch sortType {
        case .bestRate:
            return quotes.sorted { $0.expectedBuyAmount > $1.expectedBuyAmount }
        case .bestTime:
            return quotes.sorted {
                let t0 = $0.estimatedTime ?? .infinity
                let t1 = $1.estimatedTime ?? .infinity
                if t0 != t1 {
                    return t0 < t1
                }
                return $0.expectedBuyAmount > $1.expectedBuyAmount
            }
        }
    }
}
