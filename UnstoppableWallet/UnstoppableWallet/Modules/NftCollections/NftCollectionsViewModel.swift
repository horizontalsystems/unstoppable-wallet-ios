import Foundation
import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class NftCollectionsViewModel {
    private let service: NftCollectionsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    private var expandedSlugs = Set<String>()

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
        let expanded = expandedSlugs.contains(item.slug)

        return ViewItem(
                slug: item.slug,
                imageUrl: item.imageUrl,
                name: item.name,
                count: "\(item.assetItems.count)",
                expanded: expanded,
                assetViewItems: expanded ? item.assetItems.map { assetViewItem(assetItem: $0) } : []
        )
    }

    private func assetViewItem(assetItem: NftCollectionsService.AssetItem) -> AssetViewItem {
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
                collectionSlug: assetItem.collectionSlug,
                tokenId: assetItem.tokenId,
                imageUrl: assetItem.imageUrl,
                name: assetItem.name ?? "#\(assetItem.tokenId)",
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
        let slug = viewItemsRelay.value[index].slug

        if expandedSlugs.contains(slug) {
            expandedSlugs.remove(slug)
        } else {
            expandedSlugs.insert(slug)
        }

        syncState()
    }

}

extension NftCollectionsViewModel {

    struct ViewItem {
        let slug: String
        let imageUrl: String?
        let name: String
        let count: String
        let expanded: Bool
        let assetViewItems: [AssetViewItem]
    }

    struct AssetViewItem {
        let collectionSlug: String
        let tokenId: String
        let imageUrl: String?
        let name: String
        let coinPrice: String
        let fiatPrice: String?

        var uid: String {
            "\(collectionSlug)-\(tokenId)"
        }
    }

}
