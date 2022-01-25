import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class NftCollectionsViewModel {
    private let service: NftCollectionsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    private var expandedUids = Set<String>()

    init(service: NftCollectionsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        syncState()
    }

    private func syncState() {
        sync(items: service.items)
    }

    private func sync(items: [NftCollectionsService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
    }

    private func viewItem(item: NftCollectionsService.Item) -> ViewItem {
        let expanded = expandedUids.contains(item.uid)

        return ViewItem(
                uid: item.uid,
                imageUrl: item.imageUrl,
                name: item.name,
                count: "\(item.assetItems.count)",
                expanded: expanded,
                assetViewItems: expanded ? item.assetItems.map { assetViewItem(item: item, assetItem: $0) } : []
        )
    }

    private func assetViewItem(item: NftCollectionsService.Item, assetItem: NftCollectionsService.AssetItem) -> AssetViewItem {
        var coinPrice = "---"
        var fiatPrice: String?

        if let price = assetItem.price {
            let coinValue = CoinValue(kind: .platformCoin(platformCoin: price.platformCoin), value: price.value)
            if let value = ValueFormatter.instance.format(coinValue: coinValue, fractionPolicy: .threshold(high: 0.01, low: 0)) {
                coinPrice = value
            }

            if let priceItem = assetItem.priceItem {
                let currencyValue = CurrencyValue(currency: priceItem.price.currency, value: price.value * priceItem.price.value)
                fiatPrice = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.01))
            }
        }

        return AssetViewItem(
                uid: assetItem.uid,
                imageUrl: assetItem.imageUrl,
                name: assetItem.name ?? "\(item.name) #\(assetItem.tokenId)",
                coinPrice: coinPrice,
                fiatPrice: fiatPrice
        )
    }

}

extension NftCollectionsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func onTapViewItem(index: Int) {
        let uid = viewItemsRelay.value[index].uid

        if expandedUids.contains(uid) {
            expandedUids.remove(uid)
        } else {
            expandedUids.insert(uid)
        }

        syncState()
    }

}

extension NftCollectionsViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String?
        let name: String
        let count: String
        let expanded: Bool
        let assetViewItems: [AssetViewItem]
    }

    struct AssetViewItem {
        let uid: String
        let imageUrl: String
        let name: String
        let coinPrice: String
        let fiatPrice: String?
    }

}
