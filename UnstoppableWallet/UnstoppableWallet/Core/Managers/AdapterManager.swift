import Foundation
import RxSwift
import RxRelay
import MarketKit

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: AdapterFactory
    private let walletManager: WalletManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let tronKitManager: TronKitManager

    private let adapterDataReadyRelay = PublishRelay<AdapterData>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).adapter_manager", qos: .userInitiated)
    private let initAdaptersQueue = DispatchQueue(label: "\(AppConfig.label).adapter_manager.init_adapters", qos: .userInitiated)
    private var _adapterData = AdapterData(adapterMap: [:], account: nil)

    init(adapterFactory: AdapterFactory, walletManager: WalletManager, evmBlockchainManager: EvmBlockchainManager,
         tronKitManager: TronKitManager, btcBlockchainManager: BtcBlockchainManager) {
        self.adapterFactory = adapterFactory
        self.walletManager = walletManager
        self.evmBlockchainManager = evmBlockchainManager
        self.tronKitManager = tronKitManager

        walletManager.activeWalletDataUpdatedObservable
                .observeOn(SerialDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] walletData in
                    self?.initAdapters(wallets: walletData.wallets, account: walletData.account)
                })
                .disposed(by: disposeBag)

        for blockchain in evmBlockchainManager.allBlockchains {
            subscribe(disposeBag, evmBlockchainManager.evmKitManager(blockchainType: blockchain.type).evmKitUpdatedObservable) { [weak self] in self?.handleUpdatedEvmKit(blockchain: blockchain) }
        }
        subscribe(disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] in self?.handleUpdatedRestoreMode(blockchainType: $0) }
    }

    private func initAdapters(wallets: [Wallet], account: Account?) {
        initAdaptersQueue.async {
            self._initAdapters(wallets: wallets, account: account)
        }
    }

    private func _initAdapters(wallets: [Wallet], account: Account?) {
        var newAdapterMap = queue.sync { _adapterData.adapterMap }

        for wallet in wallets {
            guard newAdapterMap[wallet] == nil else {
                continue
            }
            if let adapter = adapterFactory.adapter(wallet: wallet) {
                newAdapterMap[wallet] = adapter
                adapter.start()
            }
        }

        var removedAdapters = [IAdapter]()

        for wallet in Array(newAdapterMap.keys) {
            guard !wallets.contains(wallet), let adapter = newAdapterMap.removeValue(forKey: wallet) else {
                continue
            }

            removedAdapters.append(adapter)
        }

        queue.async {
            let newAdapterData = AdapterData(adapterMap: newAdapterMap, account: account)
            self._adapterData = newAdapterData
            self.adapterDataReadyRelay.accept(newAdapterData)
        }

        removedAdapters.forEach { adapter in
            adapter.stop()
        }
    }

    private func handleUpdatedEvmKit(blockchain: Blockchain) {
        let wallets = queue.sync { _adapterData.adapterMap.keys }
        refreshAdapters(wallets: wallets.filter { wallet in
            wallet.token.blockchain == blockchain
        })
    }

    private func handleUpdatedRestoreMode(blockchainType: BlockchainType) {
        let wallets = queue.sync { _adapterData.adapterMap.keys }

        refreshAdapters(wallets: wallets.filter {
            $0.token.blockchain.type == blockchainType && $0.account.origin == .restored
        })
    }

    private func refreshAdapters(wallets: [Wallet]) {
        guard !wallets.isEmpty else {
            return
        }

        queue.sync {
            wallets.forEach {
                _adapterData.adapterMap[$0]?.stop()
                _adapterData.adapterMap[$0] = nil
            }
        }

        let activeWalletData = walletManager.activeWalletData
        initAdapters(wallets: activeWalletData.wallets, account: activeWalletData.account)
    }

}

extension AdapterManager {

    var adapterData: AdapterData {
        queue.sync { _adapterData }
    }

    var adapterDataReadyObservable: Observable<AdapterData> {
        adapterDataReadyRelay.asObservable()
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        queue.sync { _adapterData.adapterMap[wallet] }
    }

    func adapter(for token: Token) -> IAdapter? {
        queue.sync {
            guard let wallet = walletManager.activeWallets.first(where: { $0.token == token } ) else {
                return nil
            }

            return _adapterData.adapterMap[wallet]
        }
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        queue.sync { _adapterData.adapterMap[wallet] as? IBalanceAdapter }
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        queue.sync { _adapterData.adapterMap[wallet] as? IDepositAdapter }
    }

    func refresh() {
        queue.async {
            for blockchain in self.evmBlockchainManager.allBlockchains {
                self.evmBlockchainManager.evmKitManager(blockchainType: blockchain.type).evmKitWrapper?.evmKit.refresh()
            }
            var binanceKitUpdated = false

            for (wallet, adapter) in self._adapterData.adapterMap {
                switch wallet.token.blockchainType {
                case .binanceChain:
                    if !binanceKitUpdated {
                        adapter.refresh()
                        binanceKitUpdated = true
                    }
                default:
                    adapter.refresh()
                }
            }

            self.tronKitManager.tronKitWrapper?.tronKit.refresh()
        }
    }

    func refresh(wallet: Wallet) {
        queue.async {
            if let blockchainType = self.evmBlockchainManager.blockchain(token: wallet.token)?.type {
                self.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit.refresh()
            } else if wallet.token.blockchainType == .tron {
                self.tronKitManager.tronKitWrapper?.tronKit.refresh()
            } else {
                self._adapterData.adapterMap[wallet]?.refresh()
            }
        }
    }

}

extension AdapterManager {

    struct AdapterData {
        var adapterMap: [Wallet: IAdapter]
        let account: Account?
    }

}
