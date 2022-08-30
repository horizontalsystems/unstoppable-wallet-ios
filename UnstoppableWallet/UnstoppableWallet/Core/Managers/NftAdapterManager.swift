import RxSwift
import RxRelay
import MarketKit

class NftAdapterManager {
    private let adapterManager: AdapterManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let disposeBag = DisposeBag()

    private let adaptersUpdatedRelay = PublishRelay<[NftKey: INftAdapter]>()
    private var _adapterMap = [NftKey: INftAdapter]()

    private let queue = DispatchQueue(label: "io.horizontal-systems.unstoppable.nft-adapter_manager", qos: .userInitiated)

    init(adapterManager: AdapterManager, evmBlockchainManager: EvmBlockchainManager) {
        self.adapterManager = adapterManager
        self.evmBlockchainManager = evmBlockchainManager

        adapterManager.adaptersReadyObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] adapterMap in
                    self?.handleAdaptersReady(wallets: Array(adapterMap.keys))
                })
                .disposed(by: disposeBag)

        _initAdapters(wallets: Array(adapterManager.adapterMap.keys))
    }

    private func _initAdapters(wallets: [Wallet]) {
        let nftKeys = Array(Set(wallets.map { NftKey(account: $0.account, blockchainType: $0.token.blockchainType) }))

        var newAdapterMap = [NftKey: INftAdapter]()

        for nftKey in nftKeys {
            if let adapter = _adapterMap[nftKey] {
                newAdapterMap[nftKey] = adapter
                continue
            }

            if evmBlockchainManager.blockchain(type: nftKey.blockchainType) != nil {
                if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: nftKey.blockchainType).evmKitWrapper, let nftKit = evmKitWrapper.nftKit {
                    newAdapterMap[nftKey] = EvmNftAdapter(blockchainType: nftKey.blockchainType, nftKit: nftKit, address: evmKitWrapper.evmKit.address)
                }
            } else {
                // Init other blockchain adapter here (e.g. Solana)
            }
        }

//        print("NEW ADAPTERS: \(newAdapterMap.keys)")

        _adapterMap = newAdapterMap
        adaptersUpdatedRelay.accept(newAdapterMap)
    }

    private func handleAdaptersReady(wallets: [Wallet]) {
        queue.async {
            self._initAdapters(wallets: wallets)
        }
    }

}

extension NftAdapterManager {

    var adapterMap: [NftKey: INftAdapter] {
        queue.sync { _adapterMap }
    }

    var adaptersUpdatedObservable: Observable<[NftKey: INftAdapter]> {
        adaptersUpdatedRelay.asObservable()
    }

    func refresh() {
        queue.async {
            for adapter in self._adapterMap.values {
                adapter.sync()
            }
        }
    }

}
