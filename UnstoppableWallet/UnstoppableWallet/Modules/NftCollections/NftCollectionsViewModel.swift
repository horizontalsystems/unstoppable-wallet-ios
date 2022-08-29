//import Foundation
//import RxSwift
//import RxRelay
//import RxCocoa
//import CurrencyKit
//
//class NftCollectionsViewModel {
//    private let service: NftCollectionsService
//    private let disposeBag = DisposeBag()
//
//    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
//    private let expandedUidsRelay = BehaviorRelay<Set<String>>(value: Set<String>())
//
//    init(service: NftCollectionsService) {
//        self.service = service
//
//        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
//
//        syncState()
//    }
//
//    private func syncState() {
//        sync(items: service.items)
//    }
//
//    private func sync(items: [NftCollectionsService.Item]) {
//        viewItemsRelay.accept(items.map { viewItem(item: $0) })
//    }
//
//    private func viewItem(item: NftCollectionsService.Item) -> ViewItem {
//        ViewItem(
//                uid: item.uid,
//                imageUrl: item.imageUrl,
//                name: item.name,
//                count: "\(item.assetItems.count)",
//                assetViewItems: item.assetItems.map {
//                    assetViewItem(assetItem: $0)
//                }
//        )
//    }
//
//    private func assetViewItem(assetItem: NftCollectionsService.AssetItem) -> NftDoubleCell.ViewItem {
//        var coinPrice = "---"
//        var fiatPrice: String?
//
//        if let price = assetItem.price {
//            let coinValue = CoinValue(kind: .token(token: price.token), value: price.value)
//            if let value = ValueFormatter.instance.formatShort(coinValue: coinValue) {
//                coinPrice = value
//            }
//
//            if let priceItem = assetItem.priceItem {
//                fiatPrice = ValueFormatter.instance.formatShort(currency: priceItem.price.currency, value: price.value * priceItem.price.value)
//            }
//        }
//
//        return NftDoubleCell.ViewItem(
//                collectionUid: assetItem.collectionUid,
//                contractAddress: assetItem.contractAddress,
//                tokenId: assetItem.tokenId,
//                imageUrl: assetItem.imageUrl,
//                name: assetItem.name ?? "#\(assetItem.tokenId)",
//                onSale: assetItem.onSale,
//                coinPrice: coinPrice,
//                fiatPrice: fiatPrice
//        )
//    }
//
//}
//
//extension NftCollectionsViewModel {
//
//    var viewItemsDriver: Driver<[ViewItem]> {
//        viewItemsRelay.asDriver()
//    }
//
//    var expandedUidsDriver: Driver<Set<String>> {
//        expandedUidsRelay.asDriver()
//    }
//
//    func onTap(uid: String) {
//        var expandedUids = expandedUidsRelay.value
//
//        if expandedUids.contains(uid) {
//            expandedUids.remove(uid)
//        } else {
//            expandedUids.insert(uid)
//        }
//
//        expandedUidsRelay.accept(expandedUids)
//    }
//
//}
//
//extension NftCollectionsViewModel {
//
//    struct ViewItem {
//        let uid: String
//        let imageUrl: String?
//        let name: String
//        let count: String
//        let assetViewItems: [NftDoubleCell.ViewItem]
//    }
//
//}
