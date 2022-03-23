import RxSwift
import RxRelay

class NftCollectionAssetsService {
    private let collectionUid: String
    private let provider: HsNftProvider
    private let coinPriceService: WalletCoinPriceService
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var cursor: String?
    private var loadingMore = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-collection-assets-service", qos: .userInitiated)

    init(collectionUid: String, provider: HsNftProvider, coinPriceService: WalletCoinPriceService) {
        self.collectionUid = collectionUid
        self.provider = provider
        self.coinPriceService = coinPriceService

        _loadInitial()
    }

    private func _loadInitial() {
        disposeBag = DisposeBag()

        state = .loading

        provider.assetsSingle(collectionUid: collectionUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] pagedAssets in
                    self?.handle(pagedAssets: pagedAssets)
                }, onError: { [weak self] error in
                    self?.handle(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func _loadMore() {
        guard cursor != nil else {
            return
        }

        guard !loadingMore else {
            return
        }

        loadingMore = true

        provider.assetsSingle(collectionUid: collectionUid, cursor: cursor)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] pagedAssets in
                    self?.handleMore(pagedAssets: pagedAssets)
                    self?.loadingMore = false
                }, onError: { [weak self] error in
                    self?.loadingMore = false
                })
                .disposed(by: disposeBag)
    }

    private func handle(pagedAssets: PagedNftAssets) {
        queue.async {
            self.cursor = pagedAssets.cursor
            self.state = .loaded(items: self.items(assets: pagedAssets.assets), allLoaded: self.cursor == nil)
        }
    }

    private func handleMore(pagedAssets: PagedNftAssets) {
        queue.async {
            guard case .loaded(let items, _) = self.state else {
                return
            }

            self.cursor = pagedAssets.cursor
            self.state = .loaded(items: items + self.items(assets: pagedAssets.assets), allLoaded: self.cursor == nil)
        }
    }

    private func handle(error: Error) {
        queue.async {
            self.state = .failed(error: error)
        }
    }

    private func items(assets: [NftAsset]) -> [Item] {
        let items = assets.map { asset in
            Item(asset: asset, price: asset.lastSalePrice)
        }

        updatePriceItems(items: items, map: coinPriceService.itemMap(coinUids: Array(allCoinUids(items: items))))

        return items
    }

    private func allCoinUids(items: [Item]) -> Set<String> {
        var uids = Set<String>()

        for item in items {
            if let price = item.price {
                uids.insert(price.platformCoin.coin.uid)
            }
        }

        return uids
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            item.priceItem = item.price.flatMap { map[$0.platformCoin.coin.uid] }
        }
    }

}

extension NftCollectionAssetsService: IWalletRateServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            guard case .loaded(let items, let allLoaded) = self.state else {
                return
            }

            self.updatePriceItems(items: items, map: self.coinPriceService.itemMap(coinUids: Array(self.allCoinUids(items: items))))
            self.state = .loaded(items: items, allLoaded: allLoaded)
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            guard case .loaded(let items, let allLoaded) = self.state else {
                return
            }

            self.updatePriceItems(items: items, map: itemsMap)
            self.state = .loaded(items: items, allLoaded: allLoaded)
        }
    }

}

extension NftCollectionAssetsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func reload() {
        queue.async {
            self._loadInitial()
        }
    }

    func loadMore() {
        queue.async {
            self._loadMore()
        }
    }

}

extension NftCollectionAssetsService {

    enum State {
        case loading
        case loaded(items: [Item], allLoaded: Bool)
        case failed(error: Error)
    }

    class Item {
        let asset: NftAsset
        let price: NftPrice?
        var priceItem: WalletCoinPriceService.Item?

        init(asset: NftAsset, price: NftPrice?) {
            self.asset = asset
            self.price = price
        }
    }

}
