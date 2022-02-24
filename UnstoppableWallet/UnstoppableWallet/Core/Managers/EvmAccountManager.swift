import RxSwift
import MarketKit
import HsToolKit
import EthereumKit

class EvmAccountManager {
    private let blockchain: EvmBlockchain
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let coinManager: CoinManager
    private let syncSourceManager: EvmSyncSourceManager
    private let evmKitManager: EvmKitManager
    private let provider: EnableCoinsEip20Provider
    private let storage: IEvmAccountSyncStateStorage

    private let disposeBag = DisposeBag()
    private var internalDisposeBag = DisposeBag()

    private var syncing = false

    init(blockchain: EvmBlockchain, accountManager: IAccountManager, walletManager: WalletManager, coinManager: CoinManager, syncSourceManager: EvmSyncSourceManager, evmKitManager: EvmKitManager, provider: EnableCoinsEip20Provider, storage: IEvmAccountSyncStateStorage) {
        self.blockchain = blockchain
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinManager = coinManager
        self.syncSourceManager = syncSourceManager
        self.evmKitManager = evmKitManager
        self.provider = provider
        self.storage = storage

        subscribe(ConcurrentDispatchQueueScheduler(qos: .utility), disposeBag, evmKitManager.evmKitCreatedObservable) { [weak self] in self?.handleEvmKitCreated() }
    }

    private func handleEvmKitCreated() {
        internalDisposeBag = DisposeBag()

        sync()
        subscribeToTransactions()
    }

    private func sync() {
        guard let account = accountManager.activeAccount else {
            return
        }

        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
            return
        }

        guard !syncing else {
            return
        }

        syncing = true

//        print("Sync: \(evmKitWrapper.blockchain.name)")

        let chainId = evmKitManager.chain.id
        var startBlock = 0

        if let state = storage.evmAccountSyncState(accountId: account.id, chainId: chainId) {
            startBlock = state.lastBlockNumber + 1
        }

        let syncSource = syncSourceManager.syncSource(account: account, blockchain: blockchain)

        Single.zip(
                        provider.blockNumberSingle(syncSource: syncSource),
                        provider.coinTypesSingle(syncSource: syncSource, address: evmKitWrapper.evmKit.address.hex, startBlock: startBlock)
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] blockNumber, coinTypes in
//                    print("\(evmKitWrapper.evmKit.networkType) --- count: \(coinTypes.count) --- blockNumber: \(blockNumber)")

                    self?.handle(coinTypes: coinTypes, account: account)

                    let state = EvmAccountSyncState(accountId: account.id, chainId: chainId, lastBlockNumber: blockNumber)
                    self?.storage.save(evmAccountSyncState: state)

                    self?.syncing = false
                }, onError: { [weak self] _ in
                    self?.syncing = false
                })
                .disposed(by: internalDisposeBag)
    }

    private func subscribeToTransactions() {
        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
            return
        }

//        print("Subscribe: \(evmKitWrapper.evmKit.networkType)")

        evmKitWrapper.evmKit.allTransactionsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] transactions in
                    self?.handle(transactions: transactions)
                })
                .disposed(by: internalDisposeBag)
    }

    private func handle(transactions: [FullTransaction]) {
//        print("Tx count: \(transactions.count)")

        guard let account = accountManager.activeAccount else {
            return
        }

        let lastBlockNumber = storage.evmAccountSyncState(accountId: account.id, chainId: evmKitManager.chain.id)?.lastBlockNumber ?? 0

        for tx in transactions {
//            print("TX: \(tx.receiptWithLogs?.receipt.blockNumber) --- \(lastBlockNumber)")
            if let blockNumber = tx.receiptWithLogs?.receipt.blockNumber, blockNumber > lastBlockNumber {
//                print("newer block: \(blockNumber), last - \(lastBlockNumber)")
                sync()
                return
            }
        }
    }

    private func handle(coinTypes: [CoinType], account: Account) {
        guard !coinTypes.isEmpty else {
            return
        }

        do {
            let platformCoins = try coinManager.platformCoins(coinTypes: coinTypes)

//            print("Platform coins: \(platformCoins.count)")

            var map = [CoinType: PlatformCoin]()
            for platformCoin in platformCoins {
                map[platformCoin.coinType] = platformCoin
            }

            handle(platformCoins: platformCoins, account: account)
        } catch {
            // do nothing
        }
    }

    private func handle(platformCoins: [PlatformCoin], account: Account) {
        guard !platformCoins.isEmpty else {
            return
        }

        let wallets = platformCoins.map { Wallet(platformCoin: $0, account: account) }
        let existingWallets = walletManager.activeWallets
        let newWallets = wallets.filter { !existingWallets.contains($0) }

//        print("New wallets: \(newWallets.count)")

        guard !newWallets.isEmpty else {
            return
        }

        walletManager.save(wallets: newWallets)
    }

}
