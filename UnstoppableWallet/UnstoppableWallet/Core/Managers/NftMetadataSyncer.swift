import Foundation
import RxSwift
import HsToolKit
import MarketKit

class NftMetadataSyncer {
    private let syncThreshold: TimeInterval = 1 * 60 * 60 // 1 hour

    private let nftAdapterManager: NftAdapterManager
    private let nftMetadataManager: NftMetadataManager
    private let nftStorage: NftStorage
    private let disposeBag = DisposeBag()
    private var adapterDisposeBag = DisposeBag()

    init(nftAdapterManager: NftAdapterManager, nftMetadataManager: NftMetadataManager, nftStorage: NftStorage) {
        self.nftAdapterManager = nftAdapterManager
        self.nftMetadataManager = nftMetadataManager
        self.nftStorage = nftStorage

        nftAdapterManager.adaptersUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] adapterMap in
                    self?.sync(adapterMap: adapterMap)
                    self?.subscribeToAdapterRecords(adapterMap: adapterMap)
                })
                .disposed(by: disposeBag)

        subscribeToAdapterRecords(adapterMap: nftAdapterManager.adapterMap)
    }

    private func subscribeToAdapterRecords(adapterMap: [NftKey: INftAdapter]) {
        adapterDisposeBag = DisposeBag()

        for (nftKey, adapter) in adapterMap {
            adapter.nftRecordsObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onNext: { [weak self] _ in
                        self?.sync(nftKey: nftKey, adapter: adapter, force: true)
                    })
                    .disposed(by: adapterDisposeBag)
        }
    }

    private func sync(adapterMap: [NftKey: INftAdapter], force: Bool = false) {
        guard !adapterMap.isEmpty else {
            return
        }

        for (nftKey, adapter) in adapterMap {
            sync(nftKey: nftKey, adapter: adapter, force: force)
        }
    }

    private func sync(nftKey: NftKey, adapter: INftAdapter, force: Bool = false) {
        if !force, let timestamp = nftStorage.lastSyncTimestamp(nftKey: nftKey), Date().timeIntervalSince1970 - timestamp < syncThreshold {
            return
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

    private func handle(addressMetadata: NftAddressMetadata, nftKey: NftKey) {
//        print("SYNCED: \(nftKey.blockchainType) --- \(addressMetadata.collections.count) --- \(addressMetadata.assets.count)")

        nftStorage.save(lastSyncTimestamp: Date().timeIntervalSince1970, nftKey: nftKey)
        nftMetadataManager.handle(addressMetadata: addressMetadata, nftKey: nftKey)
    }

}

extension NftMetadataSyncer {

    func sync() {
        sync(adapterMap: nftAdapterManager.adapterMap)
    }

    func forceSync() {
        sync(adapterMap: nftAdapterManager.adapterMap, force: true)
    }

}
