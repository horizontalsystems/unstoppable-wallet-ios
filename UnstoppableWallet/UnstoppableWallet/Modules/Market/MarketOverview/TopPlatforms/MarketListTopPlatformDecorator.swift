import CurrencyKit
import MarketKit

protocol IMarketListTopPlatformDecoratorService {
    var currency: Currency { get }
}

class MarketListTopPlatformDecorator {
    typealias Item = MarketKit.TopPlatform

    private let service: IMarketListTopPlatformDecoratorService

    var timePeriod: MarketOverviewTopPlatformsService.TimePeriod  = .day

    init(service: IMarketListTopPlatformDecoratorService) {
        self.service = service
    }

}

extension MarketListTopPlatformDecorator: IMarketListDecorator {

    func listViewItem(item: MarketKit.TopPlatform) -> MarketModule.ListViewItem {
        let currency = service.currency

        let protocols = item.protocolsCount.map { "market.top.protocols".localized + " \($0)" } ?? ""

        let marketCap = item.marketCap.flatMap {
            CurrencyCompactFormatter.instance.format(
                    currency: currency,
                    value: $0
            )
        } ?? "n/a".localized

        let rankDiff: Int?
        let diff: Decimal?

        switch timePeriod {
        case .day:
            diff = item.oneDayChange
            rankDiff = item.oneDayRank
        case .week:
            diff = item.sevenDayChange
            rankDiff = item.sevenDaysRank
        case .month:
            diff = item.thirtyDayChange
            rankDiff = item.thirtyDaysRank
        }

        let dataValue: MarketModule.MarketDataValue = .diff(diff)

        return MarketModule.ListViewItem(
                uid: item.uid,
                iconUrl: item.fullCoin?.coin.imageUrl ?? "",
                iconPlaceholderName: item.fullCoin?.placeholderImageName ?? "",
                name: item.name,
                code: protocols,
                rank: item.rank.map { "\($0)" },
                price: marketCap,
                dataValue: dataValue
        )
    }

}
