import RxSwift
import MarketKit
import HsToolKit
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit

class EvmAccountManager {
    private let blockchain: EvmBlockchain
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit
    private let evmKitManager: EvmKitManager
    private let provider: HsTokenBalanceProvider
    private let storage: EvmAccountSyncStateStorage

    private let disposeBag = DisposeBag()
    private var internalDisposeBag = DisposeBag()

    private var syncing = false

    init(blockchain: EvmBlockchain, accountManager: AccountManager, walletManager: WalletManager, marketKit: MarketKit.Kit, evmKitManager: EvmKitManager, provider: HsTokenBalanceProvider, storage: EvmAccountSyncStateStorage) {
        self.blockchain = blockchain
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit
        self.evmKitManager = evmKitManager
        self.provider = provider
        self.storage = storage

        subscribe(ConcurrentDispatchQueueScheduler(qos: .utility), disposeBag, evmKitManager.evmKitCreatedObservable) { [weak self] in self?.handleEvmKitCreated() }
    }

    private func handleEvmKitCreated() {
        internalDisposeBag = DisposeBag()

        initialSync()
        subscribeToTransactions()
    }

    private func initialSync() {
        guard let account = accountManager.activeAccount else {
//            print("Initial Sync: \(blockchain.name): no active account")
            return
        }

        let chainId = evmKitManager.chain.id
        let syncState = storage.evmAccountSyncState(accountId: account.id, chainId: chainId)
        let lastBlockNumber = syncState?.lastBlockNumber ?? 0

        guard lastBlockNumber == 0 else  {
//            print("Initial Sync: \(blockchain.name): last block is not 0")
            return
        }

        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
//            print("Initial Sync: \(blockchain.name): no EvmKitWrapper")
            return
        }

        guard !syncing else {
//            print("Initial Sync: \(blockchain.name): already syncing")
            return
        }

        syncing = true

//        print("Initial Sync: \(evmKitWrapper.blockchain.name): start syncing...")

        if syncState == nil {
            provider.blockNumberSingle(evmBlockchain: blockchain)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onSuccess: { [weak self] blockNumber in
//                        print("Only block number: \(evmKitWrapper.blockchain.name) - \(blockNumber)")

                        let state = EvmAccountSyncState(accountId: account.id, chainId: chainId, lastBlockNumber: blockNumber)
                        self?.storage.save(evmAccountSyncState: state)

                        self?.syncing = false
                    }, onError: { [weak self] _ in
                        self?.syncing = false
                    })
                    .disposed(by: internalDisposeBag)
        } else {
            provider.addressInfoSingle(evmBlockchain: blockchain, address: evmKitWrapper.evmKit.address.hex)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onSuccess: { [weak self] info in
//                        print("Full sync \(evmKitWrapper.blockchain.name) --- count: \(info.addresses.count) --- blockNumber: \(info.blockNumber)")

                        self?.handle(addresses: info.addresses, account: account)

                        let state = EvmAccountSyncState(accountId: account.id, chainId: chainId, lastBlockNumber: info.blockNumber)
                        self?.storage.save(evmAccountSyncState: state)

                        self?.syncing = false
                    }, onError: { [weak self] _ in
                        self?.syncing = false
                    })
                    .disposed(by: internalDisposeBag)
        }
    }

    private func subscribeToTransactions() {
        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
            return
        }

//        print("Subscribe: \(evmKitWrapper.evmKit.networkType)")

        evmKitWrapper.evmKit.allTransactionsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] fullTransactions in
                    self?.handle(fullTransactions: fullTransactions)
                })
                .disposed(by: internalDisposeBag)
    }

    private func handle(fullTransactions: [FullTransaction]) {
//        print("Tx Sync: \(blockchain.name): full transactions: \(fullTransactions.count)")

        guard let account = accountManager.activeAccount else {
            return
        }

        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
            return
        }

        let address = evmKitWrapper.evmKit.address
        let lastBlockNumber = storage.evmAccountSyncState(accountId: account.id, chainId: evmKitManager.chain.id)?.lastBlockNumber

        var coinTypes = [CoinType]()
        var maxBlockNumber = 0

        for fullTransaction in fullTransactions {
            guard let blockNumber = fullTransaction.transaction.blockNumber, let lastBlockNumber = lastBlockNumber, blockNumber > lastBlockNumber else {
                continue
            }

            maxBlockNumber = max(maxBlockNumber, blockNumber)

            switch fullTransaction.decoration {
            case is IncomingDecoration:
                coinTypes.append(blockchain.baseCoinType)

            case let decoration as SwapDecoration:
                switch decoration.tokenOut {
                case .eip20Coin(let address): coinTypes.append(blockchain.evm20CoinType(address: address.hex))
                default: ()
                }

            case let decoration as OneInchSwapDecoration:
                switch decoration.tokenOut {
                case .eip20Coin(let address): coinTypes.append(blockchain.evm20CoinType(address: address.hex))
                default: ()
                }

            case let decoration as OneInchUnoswapDecoration:
                if let tokenOut = decoration.tokenOut {
                    switch tokenOut {
                    case .eip20Coin(let address): coinTypes.append(blockchain.evm20CoinType(address: address.hex))
                    default: ()
                    }
                }

            case let decoration as UnknownTransactionDecoration:
                if decoration.internalTransactions.contains(where: { $0.to == address }) {
                    coinTypes.append(blockchain.baseCoinType)
                }

                for eventInstance in decoration.eventInstances {
                    guard let transferEventInstance = eventInstance as? TransferEventInstance else {
                        continue
                    }

                    if fullTransaction.transaction.to == address {
                        coinTypes.append(blockchain.evm20CoinType(address: transferEventInstance.contractAddress.hex))
                    }
                }

            default: ()
            }
        }

        if maxBlockNumber != 0 {
            let state = EvmAccountSyncState(accountId: account.id, chainId: evmKitManager.chain.id, lastBlockNumber: maxBlockNumber)
            storage.save(evmAccountSyncState: state)
        }

//        print("Tx Sync: \(blockchain.name): coin types: \(coinTypes)")
        handle(coinTypes: coinTypes, account: account)
    }

    private func handle(addresses: [String], account: Account) {
        handle(coinTypes: addresses.map { blockchain.evm20CoinType(address: $0) }, account: account)
    }

    private func handle(coinTypes: [CoinType], account: Account) {
        guard !coinTypes.isEmpty else {
            return
        }

        do {
            let platformCoins = try marketKit.platformCoins(coinTypes: coinTypes)
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

extension EvmAccountManager {

    func markAutoEnable(account: Account) {
        let state = EvmAccountSyncState(accountId: account.id, chainId: evmKitManager.chain.id, lastBlockNumber: 0)
        storage.save(evmAccountSyncState: state)
    }

}

extension EvmAccountManager {

    struct AddressInfo {
        let blockNumber: Int
        let addresses: [String]
    }

}
