import Foundation
import CurrencyKit
import MarketKit

protocol IMarketListTopPlatformDecoratorService {
    var currency: Currency { get }
}

class MarketListTopPlatformDecorator {
    typealias Item = MarketKit.TopPlatform

    private let service: IMarketListTopPlatformDecoratorService

    var timePeriod: HsTimePeriod  = .day1

    init(service: IMarketListTopPlatformDecoratorService) {
        self.service = service
    }

}

extension MarketListTopPlatformDecorator: IMarketListDecorator {

    func listViewItem(item: MarketKit.TopPlatform) -> MarketModule.ListViewItem {
        let currency = service.currency

        let protocols = item.protocolsCount.map { "market.top.protocols".localized + " \($0)" } ?? ""

        let marketCap = item.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized

        let rankDiff: Int?  //todo use to show rank change on top platforms module
        let diff: Decimal?

        switch timePeriod {
        case .day1:
            diff = item.oneDayChange
            rankDiff = item.oneDayRank
        case .week1:
            diff = item.sevenDayChange
            rankDiff = item.sevenDaysRank
        case .month1:
            diff = item.thirtyDayChange
            rankDiff = item.thirtyDaysRank
        default:
            diff = 0
            print("unreachable state")
        }

        let dataValue: MarketModule.MarketDataValue = .diff(diff)

        return MarketModule.ListViewItem(
                uid: item.uid,
                iconUrl: item.imageUrl,
                iconShape: .square,
                iconPlaceholderName: "placeholder_24",
                name: item.name,
                code: protocols,
                rank: item.rank.map { "\($0)" },
                price: marketCap,
                dataValue: dataValue
        )
    }

}
