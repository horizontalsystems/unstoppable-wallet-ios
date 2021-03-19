import XRatesKit
import CoinKit

class CoinMarketsViewModel {
    private let coinCode: String
    private let tickers: [MarketTicker]

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
                    rate: "\(ticker.rate)",
                    volume: CurrencyCompactFormatter.instance.format(symbol: ticker.base, value: ticker.volume) ?? ""

            )
        }
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
