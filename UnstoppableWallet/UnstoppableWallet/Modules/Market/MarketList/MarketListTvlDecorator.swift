import CurrencyKit
import MarketKit

class MarketListTvlDecorator {
    private let service: MarketGlobalTvlMetricService

    init(service: MarketGlobalTvlMetricService) {
        self.service = service
    }

    private func priceDiff(price: Decimal?, diff: Decimal?) -> Decimal? {
        guard let price = price, let diff = diff else {
            return nil
        }

        return diff * price / (100 + diff)
    }
}

extension MarketListTvlDecorator: IMarketListDecorator {

    func listViewItem(item marketInfo: MarketInfo) -> MarketModule.ListViewItem {
        let currency = service.currency

        let diff: MarketModule.MarketDataValue
        let price = marketInfo.price.map { CurrencyValue(currency: currency, value: $0) }

        switch service.marketTvlField {
        case .diff: diff = .diff(marketInfo.priceChangeValue(type: service.marketTvlPriceChangeField))
        case .value: diff = .valueDiff(price, marketInfo.priceChangeValue(type: service.marketTvlPriceChangeField))
        }

        let priceString = marketInfo.price.flatMap {
            CurrencyCompactFormatter.instance.format(currency: currency, value: $0, alwaysSigned: false)
        } ?? "n/a".localized

        return MarketModule.ListViewItem(
                uid: marketInfo.fullCoin.coin.uid,
                iconUrl: marketInfo.fullCoin.coin.imageUrl,
                iconPlaceholderName: marketInfo.fullCoin.placeholderImageName,
                name: marketInfo.fullCoin.coin.name,
                code: marketInfo.fullCoin.coin.code,
                rank: marketInfo.fullCoin.coin.marketCapRank.map { "\($0)" },
                price: priceString,
                dataValue: diff
        )
    }

}
