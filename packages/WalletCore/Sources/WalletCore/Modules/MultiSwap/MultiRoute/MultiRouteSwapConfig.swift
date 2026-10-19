import Foundation

// When a large swap is offered as several routes, and into how many parts it is divided
enum MultiRouteSwapConfig {
    // The equivalent of 50,000 USD in each supported fiat base currency, rounded to friendly numbers.
    // Hardcoded on purpose (no remote config): re-derive from current USD rates when a currency drifts
    // by more than ~20%, or when a base currency is added to `CurrencyManager`.
    // Crypto base currencies (BTC, ETH, BNB) are disabled in the app and have no threshold.
    static let thresholds: [String: Decimal] = [
        "USD": 50000,
        "EUR": 43000,
        "GBP": 37500,
        "CHF": 40000,
        "AUD": 75000,
        "CAD": 70000,
        "SGD": 65000,
        "HKD": 390_000,
        "CNY": 355_000,
        "BRL": 275_000,
        "HUF": 17_000_000,
        "ILS": 165_000,
        "INR": 4_400_000,
        "JPY": 7_500_000,
        "NOK": 500_000,
        "PHP": 2_900_000,
        "RON": 220_000,
        "RUB": 4_000_000,
        "ZAR": 875_000,
        "ARS": 70_000_000,
    ]

    // the developer switch lowers every threshold: 50,000 USD -> 50 USD
    static let testDivider: Decimal = 1000

    // multiples of the threshold, checked in order
    static let tiers: [(multiplier: Decimal, parts: Int)] = [(10, 4), (3, 3), (1, 2)]

    static let minParts = 2

    // A part quote is not trusted when it promises more than this multiple of the single route's
    // per-part output: such an outlier would only inflate the gain shown on the bottom sheet
    static let maxPartGainFactor: Decimal = 1.5

    private static func threshold(currencyCode: String, testMode: Bool) -> Decimal? {
        guard let threshold = thresholds[currencyCode] else {
            return nil
        }

        return testMode ? threshold / testDivider : threshold
    }

    // nil when the amount is below the threshold or the currency has none
    static func routeCount(fiatAmount: Decimal, currencyCode: String, testMode: Bool) -> Int? {
        guard let threshold = threshold(currencyCode: currencyCode, testMode: testMode) else {
            return nil
        }

        return tiers.first { fiatAmount >= threshold * $0.multiplier }?.parts
    }

    // The first parts are rounded down to `decimals`, the last one takes the remainder,
    // so the parts always add up exactly to `total`
    static func splitAmounts(total: Decimal, parts: Int, decimals: Int) -> [Decimal] {
        guard parts > 0 else {
            return []
        }

        let part = (total / Decimal(parts)).roundedDown(decimal: decimals)
        let last = total - part * Decimal(parts - 1)

        return Array(repeating: part, count: parts - 1) + [last]
    }
}
