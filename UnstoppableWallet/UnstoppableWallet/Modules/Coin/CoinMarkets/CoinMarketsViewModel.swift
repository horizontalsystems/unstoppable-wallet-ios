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
                    marketImageUrl: ticker.marketImageUrl,
                    pair: "\(ticker.base)/\(ticker.target)",
                    rate: ValueFormatter.instance.format(value: ticker.rate, decimalCount: 8, symbol: ticker.target, fractionPolicy: .threshold(high: 0.01, low: 0)) ?? "",
                    volume: CurrencyCompactFormatter.instance.format(symbol: ticker.base, value: ticker.volume) ?? ""
            )
        }
    }

}

extension CoinMarketsViewModel {

    struct ViewItem {
        let market: String
        let marketImageUrl: String?
        let pair: String
        let rate: String
        let volume: String
    }

}
