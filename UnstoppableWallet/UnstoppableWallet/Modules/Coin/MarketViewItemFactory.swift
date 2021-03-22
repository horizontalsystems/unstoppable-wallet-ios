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

    private func roundedFormat(coinCode: String, value: Decimal?) -> String? {
        guard let value = value, !value.isZero, let formattedValue = coinFormatter.string(from: value as NSNumber) else {
            return nil
        }

        return "\(formattedValue) \(coinCode)"
    }

    func viewItem(marketCap: Decimal?, volume24h: Decimal?, circulatingSupply: Decimal?, totalSupply: Decimal?, currency: Currency, coinCode: String) -> CoinPageViewModel.MarketInfo {
        let marketCapString = marketCap.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }

        let volumeString = volume24h.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }
        let supplyString = roundedFormat(coinCode: coinCode, value: circulatingSupply)
        let totalSupplyString = roundedFormat(coinCode: coinCode, value: totalSupply)


        var dillutedMarketCap: Decimal?
        if let totalSupply = totalSupply,
            let supply = circulatingSupply,
            let marketCap = marketCap {

            dillutedMarketCap = marketCap * totalSupply / supply
        }

        let dillutedMarketCapString = dillutedMarketCap.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }

        return CoinPageViewModel.MarketInfo(
                marketCap: marketCapString,
                volume24h: volumeString,
                circulatingSupply: supplyString,
                totalSupply: totalSupplyString,
                dillutedMarketCap: dillutedMarketCapString
        )
    }

}
