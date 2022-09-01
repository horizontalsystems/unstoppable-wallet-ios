import RxSwift
import HsToolKit
import MarketKit

class NftMetadataSyncer {
    private let syncThreshold: TimeInterval = 1 * 60 * 60 // 1 hour

    private let nftAdapterManager: NftAdapterManager
    private let nftMetadataManager: NftMetadataManager
    private let nftStorage: NftStorage
    private let disposeBag = DisposeBag()

    init(nftAdapterManager: NftAdapterManager, nftMetadataManager: NftMetadataManager, nftStorage: NftStorage) {
        self.nftAdapterManager = nftAdapterManager
        self.nftMetadataManager = nftMetadataManager
        self.nftStorage = nftStorage

        nftAdapterManager.adaptersUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] adapterMap in
//                    print("SYNC: adapters updated: \(adapterMap.count)")
                    self?.sync(adapterMap: adapterMap)
                })
                .disposed(by: disposeBag)
    }

    private func sync(adapterMap: [NftKey: INftAdapter]) {
        guard !adapterMap.isEmpty else {
            return
        }

        let currentTimestamp = Date().timeIntervalSince1970

        for (nftKey, adapter) in adapterMap {
            if let timestamp = nftStorage.lastSyncTimestamp(nftKey: nftKey), currentTimestamp - timestamp < syncThreshold {
//                print("sync threshold: \(nftKey.blockchainType.uid)")
                continue
            }

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

        nftStorage.save(lastSyncTimestamp: Date().timeIntervalSince1970, nftKey: nftKey)
        nftMetadataManager.handle(addressMetadata: addressMetadata, nftKey: nftKey)
    }

}

extension NftMetadataSyncer {

    func sync() {
//        print("SYNC: from App Manager")
        sync(adapterMap: nftAdapterManager.adapterMap)
    }

}
