import Foundation
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

        var tvl: Decimal?
        let diff: MarketModule.MarketDataValue

        switch service.marketPlatformField {
        case .all:
            tvl = defiCoin.tvl

            var tvlChange: Decimal?
            switch service.priceChangePeriod {
            case .day1: tvlChange = defiCoin.tvlChange1d
            case .week1: tvlChange = defiCoin.tvlChange1w
            case .week2: tvlChange = defiCoin.tvlChange2w
            case .month1: tvlChange = defiCoin.tvlChange1m
            case .month3: tvlChange = defiCoin.tvlChange3m
            case .month6: tvlChange = defiCoin.tvlChange6m
            case .year1: tvlChange = defiCoin.tvlChange1y
            }

            switch service.marketTvlField {
            case .diff: diff = .diff(tvlChange)
            case .value: diff = .valueDiff(CurrencyValue(currency: currency, value: defiCoin.tvl), tvlChange)
            }
        default:
            tvl = defiCoin.chainTvls[service.marketPlatformField.chain]
            diff = .diff(nil)
        }

        return MarketModule.ListViewItem(
                uid: uid,
                iconUrl: iconUrl,
                iconShape: .round,
                iconPlaceholderName: iconPlaceholderName,
                leftPrimaryValue: name,
                leftSecondaryValue: defiCoin.chains.count == 1 ? defiCoin.chains[0] : "coin_page.tvl_rank.multi_chain".localized,
                badge: "\(defiCoin.tvlRank)",
                badgeSecondaryValue: nil,
                rightPrimaryValue: tvl.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized,
                rightSecondaryValue: diff
        )
    }

}
