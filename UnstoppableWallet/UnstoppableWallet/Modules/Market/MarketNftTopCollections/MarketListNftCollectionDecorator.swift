import Foundation
import MarketKit

protocol IMarketListNftTopCollectionDecoratorService {
    var timePeriod: HsTimePeriod { get }
}

class MarketListNftCollectionDecorator {
    typealias Item = NftCollectionItem

    private let service: IMarketListNftTopCollectionDecoratorService

    init(service: IMarketListNftTopCollectionDecoratorService) {
        self.service = service
    }

}

extension MarketListNftCollectionDecorator: IMarketListDecorator {

    func listViewItem(item: NftCollectionItem) -> MarketModule.ListViewItem {
        let collection = item.collection

        var floorPriceString = "---"

        if let floorPrice = collection.floorPrice {
            let coinValue = CoinValue(kind: .token(token: floorPrice.token), value: floorPrice.value)
            if let value = ValueFormatter.instance.formatShort(coinValue: coinValue) {
                floorPriceString = "market.top.floor_price".localized + " " + value
            }
        }


        var volumeString = "n/a".localized
        let volume = collection.volumes[service.timePeriod]
        let diff = collection.changes[service.timePeriod]

        if let volume = volume, let value = ValueFormatter.instance.formatShort(coinValue: CoinValue(kind: .token(token: volume.token), value: volume.value)) {
            volumeString = value
        }
        let dataValue: MarketModule.MarketDataValue = .diff(diff)

        return MarketModule.ListViewItem(
                uid: collection.uid,
                iconUrl: collection.thumbnailImageUrl ?? "",
                iconShape: .square,
                iconPlaceholderName: "placeholder_rectangle_32",
                leftPrimaryValue: collection.name,
                leftSecondaryValue: floorPriceString,
                badge: "\(item.index)",
                badgeSecondaryValue: nil,
                rightPrimaryValue: volumeString,
                rightSecondaryValue: dataValue
        )
    }

}
