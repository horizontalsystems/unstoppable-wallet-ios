import RxSwift
import RxRelay
import RxCocoa

class NftCollectionAssetsViewModel {
    private let service: NftCollectionAssetsService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftCollectionAssetsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.newAssetsObservable) { [weak self] in self?.handle(newAssets: $0) }

        sync(state: service.state)
    }

    private func sync(state: NftCollectionAssetsService.State) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .initialLoaded:
            let viewItem = ViewItem(
                    assetViewItems: assetViewItems(assets: service.assets),
                    allLoaded: service.allLoaded
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

    private func handle(newAssets: [NftAsset]) {
        let newAssetViewItems = assetViewItems(assets: newAssets)
        let currentViewItems: [AssetViewItem] = viewItemRelay.value?.assetViewItems ?? []

        let viewItem = ViewItem(
                assetViewItems: currentViewItems + newAssetViewItems,
                allLoaded: service.allLoaded
        )

        viewItemRelay.accept(viewItem)
    }

    private func assetViewItems(assets: [NftAsset]) -> [AssetViewItem] {
        assets.map { assetViewItem(asset: $0) }
    }

    private func assetViewItem(asset: NftAsset) -> AssetViewItem {
        AssetViewItem()
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

    func onTapRetry() {
        service.reload()
    }

    func onReachBottom() {
        service.loadMore()
    }

}

extension NftCollectionAssetsViewModel {

    struct ViewItem {
        let assetViewItems: [AssetViewItem]
        let allLoaded: Bool
    }

    struct AssetViewItem {

    }

}
