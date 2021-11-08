import CurrencyKit
import MarketKit

class MarketListMarketFieldDecorator {
    typealias Item = MarketInfo

    private let service: IMarketListDecoratorService

    var marketField: MarketModule.MarketField {
        didSet {
            service.onUpdate(marketField: marketField)
        }
    }

    init(service: IMarketListDecoratorService) {
        self.service = service
        marketField = service.initialMarketField
    }

}

extension MarketListMarketFieldDecorator: IMarketSingleSortHeaderDecorator {

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

extension MarketListMarketFieldDecorator: IMarketListDecorator {

    func listViewItem(item marketInfo: MarketInfo) -> MarketModule.ListViewItem {
        let currency = service.currency

        let price = marketInfo.price.flatMap {
            ValueFormatter.instance.format(
                    currencyValue: CurrencyValue(currency: currency, value: $0),
                    fractionPolicy: .threshold(high: 1000, low: 0.000001),
                    trimmable: false
            )
        } ?? "n/a".localized

        let dataValue: MarketModule.MarketDataValue

        switch marketField {
        case .price: dataValue = .diff(marketInfo.priceChangeValue(type: service.priceChangeType))
        case .volume: dataValue = .volume(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.totalVolume) ?? "n/a".localized)
        case .marketCap: dataValue = .marketCap(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.marketCap) ?? "n/a".localized)
        }

        return MarketModule.ListViewItem(
                uid: marketInfo.fullCoin.coin.uid,
                iconUrl: marketInfo.fullCoin.coin.imageUrl,
                iconPlaceholderName: marketInfo.fullCoin.placeholderImageName,
                name: marketInfo.fullCoin.coin.name,
                code: marketInfo.fullCoin.coin.code,
                rank: marketInfo.fullCoin.coin.marketCapRank.map { "\($0)" },
                price: price,
                dataValue: dataValue
        )
    }

}
