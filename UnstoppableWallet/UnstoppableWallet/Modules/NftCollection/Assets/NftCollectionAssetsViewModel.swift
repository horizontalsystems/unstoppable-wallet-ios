import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class NftCollectionAssetsViewModel {
    private let service: NftCollectionAssetsService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftCollectionAssetsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: NftCollectionAssetsService.State) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .loaded(let items, let allLoaded):
            let viewItem = ViewItem(
                    assetViewItems: items.map { assetViewItem(item: $0) },
                    allLoaded: allLoaded
            )

            viewItemRelay.accept(viewItem)
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func assetViewItem(item: NftCollectionAssetsService.Item) -> NftDoubleCell.ViewItem {
        let asset = item.asset

        var coinPrice = "---"
        var fiatPrice: String?

        if let price = item.price {
            let coinValue = CoinValue(kind: .token(token: price.token), value: price.value)
            if let value = ValueFormatter.instance.formatShort(coinValue: coinValue) {
                coinPrice = value
            }

            if let priceItem = item.priceItem {
                fiatPrice = ValueFormatter.instance.formatShort(currency: priceItem.price.currency, value: price.value * priceItem.price.value)
            }
        }

        return NftDoubleCell.ViewItem(
                providerCollectionUid: asset.providerCollectionUid,
                nftUid: asset.nftUid,
                imageUrl: asset.previewImageUrl,
                name: asset.displayName,
                count: nil,
                onSale: asset.saleInfo != nil,
                coinPrice: coinPrice,
                fiatPrice: fiatPrice
        )
    }

}

extension NftCollectionAssetsViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onLoad() {
        service.loadInitial()
    }

    func onTapRetry() {
        service.reload()
    }

    func onReachBottom() {
        service.loadMore()
    }

}

extension NftCollectionAssetsViewModel {

    struct ViewItem {
        let assetViewItems: [NftDoubleCell.ViewItem]
        let allLoaded: Bool
    }

}
