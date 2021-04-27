import Foundation
import CurrencyKit

class MarketViewItemFactory {
    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private let ratioFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private func roundedFormat(coinCode: String, value: Decimal?) -> String? {
        guard let value = value, !value.isZero, let formattedValue = coinFormatter.string(from: value as NSNumber) else {
            return nil
        }

        return "\(formattedValue) \(coinCode)"
    }

    func viewItem(marketCap: Decimal?, dilutedMarketCap: Decimal?, volume24h: Decimal?, tvl: Decimal?, circulatingSupply: Decimal?, totalSupply: Decimal?, currency: Currency, coinCode: String) -> CoinPageViewModel.MarketInfo {
        let marketCapString = marketCap.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }

        let volumeString = volume24h.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }
        let tvlString = tvl.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }
        let dilutedMarketCapString = dilutedMarketCap.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }
        let supplyString = roundedFormat(coinCode: coinCode, value: circulatingSupply)
        let totalSupplyString = roundedFormat(coinCode: coinCode, value: totalSupply)

        var marketCapTvlRatio: String?

        if let marketCap = marketCap, let tvl = tvl {
            let ratio = marketCap / tvl
            marketCapTvlRatio = ratioFormatter.string(from: ratio as NSNumber)
        }

        return CoinPageViewModel.MarketInfo(
                marketCap: marketCapString,
                volume24h: volumeString,
                tvl: tvlString,
                marketCapTvlRatio: marketCapTvlRatio,
                circulatingSupply: supplyString,
                totalSupply: totalSupplyString,
                dilutedMarketCap: dilutedMarketCapString
        )
    }

}
