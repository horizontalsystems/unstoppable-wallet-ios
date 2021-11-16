import RxSwift
import HsToolKit
import MarketKit
import StorageKit

class RestoreCustomTokenWorker {
    private let localStorageKey = "restore-custom-token-worker-run"

    private let coinManager: CoinManager
    private let walletManager: WalletManager
    private let storage: IEnabledWalletStorage
    private let localStorage: StorageKit.ILocalStorage
    private let networkManager: NetworkManager
    private let disposeBag = DisposeBag()

    init(coinManager: CoinManager, walletManager: WalletManager, storage: IEnabledWalletStorage, localStorage: StorageKit.ILocalStorage, networkManager: NetworkManager) {
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.storage = storage
        self.localStorage = localStorage
        self.networkManager = networkManager
    }

    private func customTokenSingle(coinType: CoinType) -> Single<CustomToken>? {
        switch coinType {
        case .erc20(let address):
            let service = AddEvmTokenBlockchainService(blockchain: .ethereum, networkManager: networkManager)
            return service.customTokenSingle(reference: address)
        case .bep20(let address):
            let service = AddEvmTokenBlockchainService(blockchain: .binanceSmartChain, networkManager: networkManager)
            return service.customTokenSingle(reference: address)
        case .bep2(let symbol):
            let service = AddBep2TokenBlockchainService(networkManager: networkManager)
            return service.customTokenSingle(reference: symbol)
        default:
            return nil
        }
    }

    private func joinedCustomTokensSingle(coinTypes: [CoinType]) -> Single<[CustomToken]> {
        let singles: [Single<CustomToken?>] = coinTypes.map { coinType in
            guard let single = customTokenSingle(coinType: coinType) else {
                return Single.just(nil)
            }

            return single
                    .map { customToken -> CustomToken? in customToken}
                    .catchErrorJustReturn(nil)
        }

        return Single.zip(singles) { customTokens in
            customTokens.compactMap { $0 }
        }
    }

}

extension RestoreCustomTokenWorker {

    func run() throws {
        let alreadyRun: Bool = localStorage.value(for: localStorageKey) ?? false

        guard !alreadyRun else {
            return
        }

        localStorage.set(value: true, for: localStorageKey)

        let enabledWallets = storage.enabledWallets
        let coinTypeIds = enabledWallets.map { $0.coinId }
        let platformCoins = try coinManager.platformCoins(coinTypeIds: coinTypeIds)

        let existingCoinTypeIds = platformCoins.map { $0.coinType.id }
        let missingCoinTypeIds = coinTypeIds.filter { !existingCoinTypeIds.contains($0) }

        guard !missingCoinTypeIds.isEmpty else {
            return
        }

        joinedCustomTokensSingle(coinTypes: missingCoinTypeIds.map { CoinType(id: $0) })
                .subscribe(onSuccess: { [weak self] tokens in
                    self?.coinManager.save(customTokens: tokens)
                    self?.walletManager.preloadWallets()
                })
                .disposed(by: disposeBag)
    }

}
