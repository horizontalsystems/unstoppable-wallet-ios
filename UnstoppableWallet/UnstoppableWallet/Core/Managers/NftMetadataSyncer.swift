import RxSwift
import HsToolKit
import MarketKit

class NftMetadataSyncer {
    private let nftAdapterManager: NftAdapterManager
    private let nftMetadataManager: NftMetadataManager
    private let disposeBag = DisposeBag()

    init(nftAdapterManager: NftAdapterManager, nftMetadataManager: NftMetadataManager) {
        self.nftAdapterManager = nftAdapterManager
        self.nftMetadataManager = nftMetadataManager

        nftAdapterManager.adaptersUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] adapterMap in
                    self?.sync(adapterMap: adapterMap)
                })
                .disposed(by: disposeBag)

        sync(adapterMap: nftAdapterManager.adapterMap)
    }

    private func sync(adapterMap: [NftKey: INftAdapter]) {
        for (nftKey, adapter) in adapterMap {
            // todo: check last sync time and check if sync is required

            nftMetadataManager.addressMetadataSingle(blockchainType: nftKey.blockchainType, address: adapter.userAddress)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onSuccess: { [weak self] addressMetadata in
                        self?.handle(addressMetadata: addressMetadata, nftKey: nftKey)
                    }, onError: { error in
                        // todo
                    })
                    .disposed(by: disposeBag)
        }
    }

    private func handle(addressMetadata: NftAddressMetadata, nftKey: NftKey) {
//        print("SYNCED: \(nftKey.blockchainType) --- \(addressMetadata.collections.count) --- \(addressMetadata.assets.count)")
        nftMetadataManager.handle(addressMetadata: addressMetadata, nftKey: nftKey)
    }

}
