import Foundation
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
        case let .fullCoin(fullCoin):
            uid = fullCoin.coin.uid
            iconUrl = fullCoin.coin.imageUrl
            iconPlaceholderName = "placeholder_circle_32"
            name = fullCoin.coin.name
        case let .defiCoin(defiName, logo):
            iconUrl = logo
            iconPlaceholderName = "placeholder_circle_32"
            name = defiName
        }

        var tvl: Decimal?
        let diff: MarketModule.MarketDataValue

        switch service.marketPlatformField {
        case .all:
            tvl = defiCoin.tvl

            var tvlChange: Decimal?
            switch service.priceChangePeriod {
            case .byPeriod(.day1): tvlChange = defiCoin.tvlChange1d
            case .byPeriod(.week1): tvlChange = defiCoin.tvlChange1w
            case .byPeriod(.week2): tvlChange = defiCoin.tvlChange2w
            case .byPeriod(.month1): tvlChange = defiCoin.tvlChange1m
            case .byPeriod(.month3): tvlChange = defiCoin.tvlChange3m
            case .byPeriod(.month6): tvlChange = defiCoin.tvlChange6m
            case .byPeriod(.year1): tvlChange = defiCoin.tvlChange1y
            default: ()
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
            iconShape: .square,
            iconPlaceholderName: iconPlaceholderName,
            leftPrimaryValue: name,
            leftSecondaryValue: defiCoin.chains.count == 1 ? defiCoin.chains[0] : "market.global.tvl_in_defi.multi_chain".localized,
            badge: "\(defiCoin.tvlRank)",
            badgeSecondaryValue: nil,
            rightPrimaryValue: tvl.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized,
            rightSecondaryValue: diff
        )
    }
}
