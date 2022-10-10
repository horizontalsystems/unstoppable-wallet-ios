import Foundation
import RxSwift
import RxRelay
import MarketKit

class NftCollectionAssetsService {
    private let blockchainType: BlockchainType
    private let providerCollectionUid: String
    private let nftMetadataManager: NftMetadataManager
    private let coinPriceService: WalletCoinPriceService
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var paginationData: PaginationData?
    private var loadingMore = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-collection-assets-service", qos: .userInitiated)

    init(blockchainType: BlockchainType, providerCollectionUid: String, nftMetadataManager: NftMetadataManager, coinPriceService: WalletCoinPriceService) {
        self.blockchainType = blockchainType
        self.providerCollectionUid = providerCollectionUid
        self.nftMetadataManager = nftMetadataManager
        self.coinPriceService = coinPriceService
    }

    private func _loadInitial() {
        disposeBag = DisposeBag()

        state = .loading

        nftMetadataManager.collectionAssetsMetadataSingle(blockchainType: blockchainType, providerCollectionUid: providerCollectionUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] (assets, paginationData) in
                    self?.handle(assets: assets, paginationData: paginationData)
                }, onError: { [weak self] error in
                    self?.handle(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func _loadMore() {
        guard paginationData != nil else {
            return
        }

        guard !loadingMore else {
            return
        }

        loadingMore = true

        nftMetadataManager.collectionAssetsMetadataSingle(blockchainType: blockchainType, providerCollectionUid: providerCollectionUid, paginationData: paginationData)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] (assets, paginationData) in
                    self?.handleMore(assets: assets, paginationData: paginationData)
                    self?.loadingMore = false
                }, onError: { [weak self] error in
                    self?.loadingMore = false
                })
                .disposed(by: disposeBag)
    }

    private func handle(assets: [NftAssetMetadata], paginationData: PaginationData?) {
        queue.async {
            self.paginationData = paginationData
            self.state = .loaded(items: self.items(assets: assets), allLoaded: self.paginationData == nil)
        }
    }

    private func handleMore(assets: [NftAssetMetadata], paginationData: PaginationData?) {
        queue.async {
            guard case .loaded(let items, _) = self.state else {
                return
            }

            self.paginationData = paginationData
            self.state = .loaded(items: items + self.items(assets: assets), allLoaded: self.paginationData == nil)
        }
    }

    private func handle(error: Error) {
        queue.async {
            self.state = .failed(error: error)
        }
    }

    private func items(assets: [NftAssetMetadata]) -> [Item] {
        let items = assets.map { asset in
            Item(asset: asset, price: asset.lastSalePrice)
        }

        updatePriceItems(items: items, map: coinPriceService.itemMap(tokens: Array(allTokens(items: items))))

        return items
    }

    private func allTokens(items: [Item]) -> Set<Token> {
        var tokens = Set<Token>()

        for item in items {
            if let price = item.price {
                tokens.insert(price.token)
            }
        }

        return tokens
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            item.priceItem = item.price.flatMap { map[$0.token.coin.uid] }
        }
    }

}

extension NftCollectionAssetsService: IWalletCoinPriceServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            guard case .loaded(let items, let allLoaded) = self.state else {
                return
            }

            self.updatePriceItems(items: items, map: self.coinPriceService.itemMap(tokens: Array(self.allTokens(items: items))))
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

    func loadInitial() {
        queue.async {
            self._loadInitial()
        }
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
        let asset: NftAssetMetadata
        let price: NftPrice?
        var priceItem: WalletCoinPriceService.Item?

        init(asset: NftAssetMetadata, price: NftPrice?) {
            self.asset = asset
            self.price = price
        }
    }

}
