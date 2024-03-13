import MarketKit

class MarketWatchlistDecorator {
    typealias Item = MarketInfo

    private let service: IMarketListDecoratorService

    var priceChangeType: MarketModule.PriceChangeType

    init(service: IMarketListDecoratorService) {
        self.service = service

        priceChangeType = MarketModule.PriceChangeType.sortingTypes.at(index: service.initialIndex) ?? .day
    }
}

extension MarketWatchlistDecorator: IMarketSingleSortHeaderDecorator {
    var allFields: [String] {
        MarketModule.PriceChangeType.sortingTypes.map(\.shortTitle)
    }

    var currentFieldIndex: Int {
        MarketModule.PriceChangeType.sortingTypes.firstIndex(of: priceChangeType) ?? 0
    }

    func setCurrentField(index: Int) {
        priceChangeType = MarketModule.PriceChangeType.sortingTypes.at(index: index) ?? .day
        service.onUpdate(index: index)
    }
}

extension MarketWatchlistDecorator: IMarketListDecorator {
    func listViewItem(item marketInfo: MarketInfo) -> MarketModule.ListViewItem {
        let currency = service.currency

        let price = marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: currency, value: $0) } ?? "n/a".localized

        let dataValue: MarketModule.MarketDataValue

        dataValue = .diff(marketInfo.priceChangeValue(type: priceChangeType))

        return MarketModule.ListViewItem(
            uid: marketInfo.fullCoin.coin.uid,
            iconUrl: marketInfo.fullCoin.coin.imageUrl,
            iconShape: .full,
            iconPlaceholderName: "placeholder_circle_32",
            leftPrimaryValue: marketInfo.fullCoin.coin.code,
            leftSecondaryValue: marketInfo.fullCoin.coin.name,
            badge: marketInfo.marketCapRank.map { "\($0)" },
            badgeSecondaryValue: nil,
            rightPrimaryValue: price,
            rightSecondaryValue: dataValue
        )
    }
}
