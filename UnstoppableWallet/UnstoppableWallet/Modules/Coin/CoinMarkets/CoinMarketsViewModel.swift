import Foundation
import XRatesKit
import CoinKit

class CoinMarketsViewModel {
    private let coinCode: String
    private let tickers: [MarketTicker]

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 8
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        return formatter
    }()

    init(coinCode: String, tickers: [MarketTicker]) {
        self.coinCode = coinCode
        self.tickers = tickers
    }

    var title: String {
        "coin_page.markets".localized(coinCode)
    }

    var viewItems: [ViewItem] {
        tickers.map { ticker in
            ViewItem(
                    market: ticker.marketName,
                    pair: "\(ticker.base)/\(ticker.target)",
                    rate: format(symbol: ticker.target, value: ticker.rate) ?? "",
                    volume: CurrencyCompactFormatter.instance.format(symbol: ticker.base, value: ticker.volume) ?? ""
            )
        }
    }

    func format(symbol: String, value: Decimal?) -> String? {
        guard let value = value, let formattedValue = coinFormatter.string(from: value as NSNumber)?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }

        return formattedValue + " " + symbol
    }

}

extension CoinMarketsViewModel {

    struct ViewItem {
        let market: String
        let pair: String
        let rate: String
        let volume: String
    }

}
