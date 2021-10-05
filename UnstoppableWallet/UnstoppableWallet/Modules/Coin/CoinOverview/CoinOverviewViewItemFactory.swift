import Foundation
import CurrencyKit

class CoinOverviewViewItemFactory {
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

    func viewItem(marketCap: Decimal?, marketCapRank: Int?, dilutedMarketCap: Decimal?, volume24h: Decimal?, tvl: Decimal?, genesisDate: TimeInterval?, circulatingSupply: Decimal?, totalSupply: Decimal?, currency: Currency, coinCode: String) -> CoinOverviewViewModel.MarketInfo {
        let marketCapString = marketCap.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }

        let volumeString = volume24h.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }
        let tvlString = tvl.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }
        let dilutedMarketCapString = dilutedMarketCap.flatMap { CurrencyCompactFormatter.instance.format(currency: currency, value: $0) }
        let genesisDateString = genesisDate.map { DateHelper.instance.formatFullDateOnly(from: Date(timeIntervalSince1970: $0)) }
        let supplyString = roundedFormat(coinCode: coinCode, value: circulatingSupply)
        let totalSupplyString = roundedFormat(coinCode: coinCode, value: totalSupply)

        return CoinOverviewViewModel.MarketInfo(
                marketCap: marketCapString,
                marketCapRank: marketCapRank.map { "#\($0)" },
                volume24h: volumeString,
                tvl: tvlString,
                genesisDate: genesisDateString,
                circulatingSupply: supplyString,
                totalSupply: totalSupplyString,
                dilutedMarketCap: dilutedMarketCapString
        )
    }

}
