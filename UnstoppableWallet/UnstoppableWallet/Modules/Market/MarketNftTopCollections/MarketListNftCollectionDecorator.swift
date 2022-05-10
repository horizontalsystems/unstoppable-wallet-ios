import Foundation

class MarketListNftCollectionDecorator {
    typealias Item = NftCollectionItem

    var volumeRange: MarketNftTopCollectionsModule.VolumeRange = .day

}

extension MarketListNftCollectionDecorator: IMarketListDecorator {

    func listViewItem(item: NftCollectionItem) -> MarketModule.ListViewItem {
        let collection = item.collection

        var floorPriceString = "---"
        var iconPlaceholderName = "icon_placeholder_24"
        if let floorPrice = collection.stats.floorPrice {
            iconPlaceholderName = floorPrice.platformCoin.fullCoin.placeholderImageName

            let coinValue = CoinValue(kind: .platformCoin(platformCoin: floorPrice.platformCoin), value: floorPrice.value)
            if let value = ValueFormatter.instance.format(coinValue: coinValue, fractionPolicy: .threshold(high: 0.01, low: 0)) {
                floorPriceString = "market.top.floor_price".localized + " " + value
            }
        }


        var volumeString = "n/a".localized
        let volume: NftPrice?
        let diff: Decimal?

        switch volumeRange {
        case .day:
            volume = collection.stats.oneDayVolume
            diff = collection.stats.oneDayChange
        case .week:
            volume = collection.stats.sevenDayVolume
            diff = collection.stats.sevenDayChange
        case .month:
            volume = collection.stats.thirtyDayVolume
            diff = collection.stats.thirtyDayChange
        }

        if let volume = volume, let value = CurrencyCompactFormatter.instance.format(symbol: volume.platformCoin.code, value: volume.value) {
            volumeString = value
        }
        let dataValue: MarketModule.MarketDataValue = .diff(diff)

        return MarketModule.ListViewItem(
                uid: collection.uid,
                iconUrl: collection.imageUrl ?? "",
                iconShape: .square,
                iconPlaceholderName: iconPlaceholderName,
                name: collection.name,
                code: floorPriceString,
                rank: "\(item.index)",
                price: volumeString,
                dataValue: dataValue
        )
    }

}
