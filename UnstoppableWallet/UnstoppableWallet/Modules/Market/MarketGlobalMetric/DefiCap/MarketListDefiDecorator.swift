import CurrencyKit
import MarketKit

class MarketListDefiDecorator {
    typealias Item = MarketGlobalDefiMetricService.DefiItem

    private let service: IMarketListDecoratorService

    var marketField: MarketModule.MarketField {
        didSet {
            service.onUpdate(marketFieldIndex: marketField.rawValue)
        }
    }

    init(service: IMarketListDecoratorService) {
        self.service = service
        marketField = MarketModule.MarketField.allCases[service.initialMarketFieldIndex]
    }

}

extension MarketListDefiDecorator: IMarketSingleSortHeaderDecorator {

    var allFields: [String] {
        MarketModule.MarketField.allCases.map { $0.title }
    }

    var currentFieldIndex: Int {
        MarketModule.MarketField.allCases.firstIndex(of: marketField) ?? 0
    }

    func setCurrentField(index: Int) {
        marketField = MarketModule.MarketField.allCases[index]
    }

}

extension MarketListDefiDecorator: IMarketListDecorator {

    func listViewItem(item: MarketGlobalDefiMetricService.DefiItem) -> MarketModule.ListViewItem {
        let marketInfo = item.marketInfo
        let currency = service.currency

        let price = marketInfo.price.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized

        let dataValue: MarketModule.MarketDataValue

        switch marketField {
        case .price: dataValue = .diff(marketInfo.priceChangeValue(type: service.priceChangeType))
        case .volume: dataValue = .volume(marketInfo.totalVolume.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized)
        case .marketCap: dataValue = .marketCap(marketInfo.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) } ?? "n/a".localized)
        }

        return MarketModule.ListViewItem(
                uid: marketInfo.fullCoin.coin.uid,
                iconUrl: marketInfo.fullCoin.coin.imageUrl,
                iconShape: .round,
                iconPlaceholderName: marketInfo.fullCoin.placeholderImageName,
                leftPrimaryValue: marketInfo.fullCoin.coin.code,
                leftSecondaryValue: marketInfo.fullCoin.coin.name,
                badge: "\(item.tvlRank)",
                badgeSecondaryValue: nil,
                rightPrimaryValue: price,
                rightSecondaryValue: dataValue
        )
    }

}
