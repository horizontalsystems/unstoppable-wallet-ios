import Foundation
import MarketKit

protocol IMarketListMarketPairDecoratorService {
    var currency: Currency { get }
}

class MarketListMarketPairDecorator {
    typealias Item = MarketPair

    private let service: IMarketListMarketPairDecoratorService

    init(service: IMarketListMarketPairDecoratorService) {
        self.service = service
    }
}

extension MarketListMarketPairDecorator: IMarketListDecorator {
    func listViewItem(item: MarketPair) -> MarketModule.ListViewItem {
        let currency = service.currency

        let volume = item.volume.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized
        let price = item.price.flatMap { ValueFormatter.instance.formatShort(value: $0, decimalCount: 8, symbol: item.target) } ?? "n/a".localized

        return MarketModule.ListViewItem(
            uid: item.uid,
            iconUrl: item.marketImageUrl,
            iconShape: .square,
            iconPlaceholderName: "placeholder_rectangle_32",
            leftPrimaryValue: "\(item.base)/\(item.target)",
            leftSecondaryValue: item.marketName,
            badge: "\(item.rank)",
            badgeSecondaryValue: nil,
            rightPrimaryValue: volume,
            rightSecondaryValue: .volume(price)
        )
    }
}
