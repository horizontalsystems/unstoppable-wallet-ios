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

    func listViewItem(marketInfo: MarketInfo) -> MarketModule.ListViewItem {
        let currency = service.currency

        let price: Decimal?
        let diff = marketInfo.priceChangeValue(type: service.priceChangeValue)

        switch service.marketTvlField {
        case .value: price = marketInfo.price
        case .dayDiff, .weekDiff: price = priceDiff(price: marketInfo.price, diff: diff)
        }

        let alwaysSigned = service.marketTvlField != .value

        let priceString = price.flatMap {
            CurrencyCompactFormatter.instance.format(currency: currency, value: $0, alwaysSigned: alwaysSigned)
        } ?? "n/a".localized

        return MarketModule.ListViewItem(
                uid: marketInfo.fullCoin.coin.uid,
                iconUrl: marketInfo.fullCoin.coin.imageUrl,
                iconPlaceholderName: marketInfo.fullCoin.placeholderImageName,
                name: marketInfo.fullCoin.coin.name,
                code: marketInfo.fullCoin.coin.code,
                rank: marketInfo.fullCoin.coin.marketCapRank.map { "\($0)" },
                price: priceString,
                dataValue: .diff(marketInfo.priceChangeValue(type: service.priceChangeValue))
        )
    }

}
