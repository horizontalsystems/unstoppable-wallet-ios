import RxSwift
import RxRelay
import MarketKit

class NftAdapterManager {
    private let adapterManager: AdapterManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let disposeBag = DisposeBag()

    private let adaptersUpdatedRelay = PublishRelay<[BlockchainType: INftAdapter]>()
    private var _adapterMap = [BlockchainType: INftAdapter]()

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
        let blockchainTypes = Array(Set(wallets.map { $0.token.blockchainType }))

        var newAdapterMap = [BlockchainType: INftAdapter]()

        for blockchainType in blockchainTypes {
            if evmBlockchainManager.blockchain(type: blockchainType) != nil {
                if let nftKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.nftKit {
                    newAdapterMap[blockchainType] = EvmNftAdapter(blockchainType: blockchainType, nftKit: nftKit)
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

    var adapterMap: [BlockchainType: INftAdapter] {
        queue.sync { _adapterMap }
    }

    var adaptersUpdatedObservable: Observable<[BlockchainType: INftAdapter]> {
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
