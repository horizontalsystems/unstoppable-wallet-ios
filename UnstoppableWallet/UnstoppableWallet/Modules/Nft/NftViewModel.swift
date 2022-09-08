import Foundation
import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class NftViewModel {
    private let service: NftService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let expandedUidsRelay = BehaviorRelay<Set<String>>(value: Set<String>())

    init(service: NftService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        syncState()
    }

    private func syncState() {
        sync(items: service.items)
    }

    private func sync(items: [NftService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
    }

    private func viewItem(item: NftService.Item) -> ViewItem {
        ViewItem(
                uid: item.uid,
                imageUrl: item.imageUrl,
                name: item.name,
                count: "\(item.count)",
                assetViewItems: item.assetItems.map {
                    assetViewItem(item: item, assetItem: $0)
                }
        )
    }

    private func assetViewItem(item: NftService.Item, assetItem: NftService.AssetItem) -> NftDoubleCell.ViewItem {
        var coinPrice = "---"
        var fiatPrice: String?

        if let price = assetItem.price {
            let coinValue = CoinValue(kind: .token(token: price.token), value: price.value)
            if let value = ValueFormatter.instance.formatShort(coinValue: coinValue) {
                coinPrice = value
            }

            if let priceItem = assetItem.priceItem {
                fiatPrice = ValueFormatter.instance.formatShort(currency: priceItem.price.currency, value: price.value * priceItem.price.value)
            }
        }

        return NftDoubleCell.ViewItem(
                providerCollectionUid: item.providerCollectionUid,
                nftUid: assetItem.nftUid,
                imageUrl: assetItem.imageUrl,
                name: assetItem.name,
                count: assetItem.count == 1 ? nil : "\(assetItem.count)",
                onSale: assetItem.onSale,
                coinPrice: coinPrice,
                fiatPrice: fiatPrice
        )
    }

}

extension NftViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var expandedUidsDriver: Driver<Set<String>> {
        expandedUidsRelay.asDriver()
    }

    func onTriggerRefresh() {
        service.refreshMetadata()
    }

    func onTap(uid: String) {
        var expandedUids = expandedUidsRelay.value

        if expandedUids.contains(uid) {
            expandedUids.remove(uid)
        } else {
            expandedUids.insert(uid)
        }

        expandedUidsRelay.accept(expandedUids)
    }

}

extension NftViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String?
        let name: String
        let count: String
        let assetViewItems: [NftDoubleCell.ViewItem]
    }

}
