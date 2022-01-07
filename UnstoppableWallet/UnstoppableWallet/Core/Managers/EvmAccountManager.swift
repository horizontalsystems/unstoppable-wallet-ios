import RxSwift
import MarketKit
import HsToolKit

class EvmAccountManager {
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let coinManager: CoinManager
    private let evmKitManager: EvmKitManager
    private let provider: EnableCoinsEip20Provider
    private let storage: IEvmAccountSyncStateStorage

    private let disposeBag = DisposeBag()

    init(accountManager: IAccountManager, walletManager: WalletManager, coinManager: CoinManager, evmKitManager: EvmKitManager, provider: EnableCoinsEip20Provider, storage: IEvmAccountSyncStateStorage) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinManager = coinManager
        self.evmKitManager = evmKitManager
        self.provider = provider
        self.storage = storage

        subscribe(ConcurrentDispatchQueueScheduler(qos: .utility), disposeBag, evmKitManager.evmKitCreatedObservable) { [weak self] in self?.sync() }
    }

    private func sync() {
        guard let account = accountManager.activeAccount else {
            return
        }

        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
            return
        }

//        print("Sync: \(evmKitWrapper.evmKit.networkType)")

        let chainId = evmKitWrapper.evmKit.networkType.chainId
        let startBlock = storage.evmAccountSyncState(accountId: account.id, chainId: chainId)?.lastTransactionBlockNumber

        provider.coinTypeInfoSingle(address: evmKitWrapper.evmKit.address.hex, startBlock: startBlock.map { $0 + 1 })
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] info in
//                    print("\(evmKitWrapper.evmKit.networkType): \(info.coinTypes.count): \(info.lastTransactionBlockNumber): \(info.coinTypes)")

                    self?.handle(coinTypes: info.coinTypes, account: account)

                    if let lastTransactionBlockNumber = info.lastTransactionBlockNumber {
                        let state = EvmAccountSyncState(accountId: account.id, chainId: chainId, lastTransactionBlockNumber: lastTransactionBlockNumber)
                        self?.storage.save(evmAccountSyncState: state)
                    }
                })
                .disposed(by: disposeBag)
    }

    private func handle(coinTypes: [CoinType], account: Account) {
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
        let wallets = platformCoins.map { Wallet(platformCoin: $0, account: account) }

        let existingWallets = walletManager.activeWallets

        let newWallets = wallets.filter { !existingWallets.contains($0) }

//        print("New wallets: \(newWallets.count)")

        if !newWallets.isEmpty {
            walletManager.save(wallets: newWallets)
        }
    }

}
