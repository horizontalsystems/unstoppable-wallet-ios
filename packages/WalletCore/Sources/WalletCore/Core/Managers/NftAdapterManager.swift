import Foundation
import MarketKit
import RxRelay
import RxSwift

class NftAdapterManager {
    private let walletManager: WalletManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let disposeBag = DisposeBag()

    private let adaptersUpdatedRelay = PublishRelay<[NftKey: INftAdapter]>()
    private var _adapterMap = [NftKey: INftAdapter]()

    private let queue = DispatchQueue(label: "\(AppConfig.label).nft-adapter_manager", qos: .userInitiated)

    init(walletManager: WalletManager, evmBlockchainManager: EvmBlockchainManager) {
        self.walletManager = walletManager
        self.evmBlockchainManager = evmBlockchainManager

        walletManager.activeWalletDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] walletData in
                self?.handleAdaptersReady(wallets: walletData.wallets)
            })
            .disposed(by: disposeBag)

        _initAdapters(wallets: walletManager.activeWallets)
    }

    private func _initAdapters(wallets: [Wallet]) {
        let nftKeys = Array(Set(wallets.map { NftKey(account: $0.account, blockchainType: $0.token.blockchainType) }))

        var newAdapterMap = [NftKey: INftAdapter]()

        for nftKey in nftKeys {
            if let adapter = _adapterMap[nftKey] {
                newAdapterMap[nftKey] = adapter
                continue
            }

            // NFT adapters are not created — NFT support is removed (EvmKitWrapper no longer exposes nftKit).
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

    func adapter(nftKey: NftKey) -> INftAdapter? {
        queue.sync { _adapterMap[nftKey] }
    }

    func refresh() {
        queue.async {
            for adapter in self._adapterMap.values {
                adapter.sync()
            }
        }
    }
}
