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
        tickers.compactMap { ticker in
            guard let base = ticker.base, let volume = ticker.volume else {
                return nil
            }
            return ViewItem(
                    market: ticker.marketName,
                    pair: "\(ticker.base)/\(ticker.target)",
                    rate: "\(ticker.rate)",
                    volume: CurrencyCompactFormatter.instance.format(symbol: base, value: volume) ?? ""

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
