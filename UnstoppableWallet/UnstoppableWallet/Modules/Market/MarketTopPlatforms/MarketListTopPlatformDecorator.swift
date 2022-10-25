import Foundation
import CurrencyKit
import MarketKit
import ComponentKit

protocol IMarketListTopPlatformDecoratorService {
    var currency: Currency { get }
    var timePeriod: HsTimePeriod { get }
}

class MarketListTopPlatformDecorator {
    typealias Item = MarketKit.TopPlatform

    private let service: IMarketListTopPlatformDecoratorService

    init(service: IMarketListTopPlatformDecoratorService) {
        self.service = service
    }

}

extension MarketListTopPlatformDecorator: IMarketListDecorator {

    func listViewItem(item: MarketKit.TopPlatform) -> MarketModule.ListViewItem {
        let currency = service.currency

        let protocols = item.protocolsCount.map { "market.top.protocols".localized + " \($0)" } ?? ""

        let marketCap = item.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized

        let rank = item.rank
        let rankDiff: Int? = rank.flatMap { rank in
            item.ranks[service.timePeriod].flatMap { pastRank in
                let diff = pastRank - rank
                return diff == 0 ? nil : diff
            }
        }
        let rankChange: BadgeView.Change? = rankDiff.map { $0 < 0 ? .down("\(abs($0))") : .up("\($0)") }

        let diff = item.changes[service.timePeriod]
        let dataValue: MarketModule.MarketDataValue = .diff(diff)

        return MarketModule.ListViewItem(
                uid: item.blockchain.uid,
                iconUrl: item.blockchain.type.imageUrl,
                iconShape: .square,
                iconPlaceholderName: "placeholder_24",
                leftPrimaryValue: item.blockchain.name,
                leftSecondaryValue: protocols,
                badge: rank.map { "\($0)" },
                badgeSecondaryValue: rankChange,
                rightPrimaryValue: marketCap,
                rightSecondaryValue: dataValue
        )
    }

}
