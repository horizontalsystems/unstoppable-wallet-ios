import Foundation

class AppConfigProvider: IAppConfigProvider {

    let reachabilityHost = "ipfs.horizontalsystems.xyz"
    let ratesApiUrl = "https://ipfs.horizontalsystems.xyz/ipns/Qmd4Gv2YVPqs6dmSy1XEq7pQRSgLihqYKL2JjK7DMUFPVz/io-hs/data/xrates"

    var testMode: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "TestMode") as? String == "true"
    }

    var defaultWords: [String] {
        guard let wordsString = Bundle.main.object(forInfoDictionaryKey: "DefaultWords") as? String else {
            return []
        }

        return wordsString.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    var disablePinLock: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "DisablePinLock") as? String == "true"
    }

    let currencies: [Currency] = [
        Currency(code: "USD", symbol: "\u{0024}"),
        Currency(code: "EUR", symbol: "\u{20AC}"),
        Currency(code: "GBP", symbol: "\u{00A3}"),
        Currency(code: "JPY", symbol: "\u{00A5}"),
        Currency(code: "AUD", symbol: "\u{20B3}"),
        Currency(code: "CAD", symbol: "\u{0024}"),
        Currency(code: "CHF", symbol: "\u{20A3}"),
        Currency(code: "CNY", symbol: "\u{00A5}"),
        Currency(code: "KRW", symbol: "\u{20A9}"),
        Currency(code: "RUB", symbol: "\u{20BD}"),
        Currency(code: "TRY", symbol: "\u{20BA}")
    ]

    var defaultCoins: [Coin] {
        let suffix = testMode ? "t" : ""
        return [
            Coin(title: "Bitcoin", code: "BTC\(suffix)", type: .bitcoin),
            Coin(title: "Bitcoin Cash", code: "BCH\(suffix)", type: .bitcoinCash),
            Coin(title: "Ethereum", code: "ETH\(suffix)", type: .ethereum)
        ]
    }

}
