import Foundation

class AppConfigProvider: IAppConfigProvider {

    let reachabilityHost = "ipfs.horizontalsystems.xyz"
    let ratesApiUrl = "https://ipfs.horizontalsystems.xyz/ipns/Qmd4Gv2YVPqs6dmSy1XEq7pQRSgLihqYKL2JjK7DMUFPVz/io-hs/data/xrates"

    var enabledCoinCodes: [CoinCode] {
        if let coins = Bundle.main.object(forInfoDictionaryKey: "Enabled Coins") as? String {
            return coins.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
        }
        return []
    }

    let currencies: [Currency] = [
        Currency(code: "USD", symbol: "\u{0024}"),
        Currency(code: "EUR", symbol: "\u{20AC}"),
        Currency(code: "RUB", symbol: "\u{20BD}"),
        Currency(code: "AUD", symbol: "\u{20B3}"),
        Currency(code: "CAD", symbol: "\u{0024}"),
        Currency(code: "CHF", symbol: "\u{20A3}"),
        Currency(code: "CNY", symbol: "\u{00A5}"),
        Currency(code: "GBP", symbol: "\u{00A3}"),
        Currency(code: "JPY", symbol: "\u{00A5}")
    ]

}
