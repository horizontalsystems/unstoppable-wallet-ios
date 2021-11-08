import CurrencyKit
import MarketKit

class MarketListTvlDecorator {
    typealias Item = DefiCoin

    private let service: MarketGlobalTvlMetricService

    init(service: MarketGlobalTvlMetricService) {
        self.service = service
    }

}

extension MarketListTvlDecorator: IMarketListDecorator {

    func listViewItem(item defiCoin: DefiCoin) -> MarketModule.ListViewItem {
        let currency = service.currency

        var tvlChange: Decimal?
        switch service.marketTvlPriceChangeField {
        case .day: tvlChange = defiCoin.tvlChange1d
        case .week: tvlChange = defiCoin.tvlChange7d
        case .month: tvlChange = defiCoin.tvlChange30d
        default: ()
        }

        let diff: MarketModule.MarketDataValue
        switch service.marketTvlField {
        case .diff: diff = .diff(tvlChange)
        case .value: diff = .valueDiff(CurrencyValue(currency: currency, value: defiCoin.tvl), tvlChange)
        }

        var uid: String?
        let iconUrl: String
        let iconPlaceholderName: String
        let name: String

        switch defiCoin.type {
        case .fullCoin(let fullCoin):
            uid = fullCoin.coin.uid
            iconUrl = fullCoin.coin.imageUrl
            iconPlaceholderName = fullCoin.placeholderImageName
            name = fullCoin.coin.name
        case .defiCoin(let defiName, let logo):
            iconUrl = logo
            iconPlaceholderName = "icon_placeholder_24"
            name = defiName
        }


        return MarketModule.ListViewItem(
                uid: uid,
                iconUrl: iconUrl,
                iconPlaceholderName: iconPlaceholderName,
                name: name,
                code: defiCoin.chains.count == 1 ? defiCoin.chains[0] : "coin_page.tvl_rank.multi_chain".localized,
                rank: "\(defiCoin.tvlRank)",
                price: CurrencyCompactFormatter.instance.format(currency: currency, value: defiCoin.tvl, alwaysSigned: false) ?? "n/a".localized,
                dataValue: diff
        )
    }

}
