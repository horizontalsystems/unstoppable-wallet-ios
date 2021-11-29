import RxSwift
import RxRelay
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit

protocol IEvmKitManagerDataSource {
    var explorerApiKey: String { get }
    var evmNetworkObservable: Observable<(Account, EvmNetwork)> { get }
    func evmNetwork(account: Account) -> EvmNetwork
}

class EvmKitManager {
    private let dataSource: IEvmKitManagerDataSource
    private let disposeBag = DisposeBag()

    private weak var _evmKit: EthereumKit.Kit?

    private let evmKitUpdatedRelay = PublishRelay<Void>()
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.ethereum-kit-manager", qos: .userInitiated)

    init(dataSource: IEvmKitManagerDataSource) {
        self.dataSource = dataSource

        subscribe(disposeBag, dataSource.evmNetworkObservable) { [weak self] account, _ in
            self?.handleUpdatedNetwork(account: account)
        }
    }

    private func handleUpdatedNetwork(account: Account) {
        queue.sync {
            guard account == currentAccount else {
                return
            }

            _evmKit = nil
            evmKitUpdatedRelay.accept(())
        }
    }

    private func _evmKit(account: Account) throws -> EthereumKit.Kit {
        if let _evmKit = _evmKit, let currentAccount = currentAccount, currentAccount == account {
            return _evmKit
        }

        guard let seed = account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let evmNetwork = dataSource.evmNetwork(account: account)

        let evmKit = try EthereumKit.Kit.instance(
                seed: seed,
                networkType: evmNetwork.networkType,
                syncSource: evmNetwork.syncSource,
                etherscanApiKey: dataSource.explorerApiKey,
                walletId: account.id,
                minLogLevel: .error
        )

        Erc20Kit.Kit.addDecorator(to: evmKit)
        Erc20Kit.Kit.addTransactionSyncer(to: evmKit)

        UniswapKit.Kit.addDecorator(to: evmKit)
        UniswapKit.Kit.addTransactionWatcher(to: evmKit)

        OneInchKit.Kit.addDecorator(to: evmKit)
        OneInchKit.Kit.addTransactionWatcher(to: evmKit)

        evmKit.start()

        _evmKit = evmKit
        currentAccount = account

        return evmKit
    }

}

extension EvmKitManager {

    var evmKitUpdatedObservable: Observable<Void> {
        evmKitUpdatedRelay.asObservable()
    }

    var evmKit: EthereumKit.Kit? {
        queue.sync { _evmKit }
    }

    func evmKit(account: Account) throws -> EthereumKit.Kit {
        try queue.sync { try _evmKit(account: account)  }
    }

}

class EthKitManagerDataSource: IEvmKitManagerDataSource {
    private let appConfigProvider: AppConfigProvider
    private let accountSettingManager: AccountSettingManager

    init(appConfigProvider: AppConfigProvider, accountSettingManager: AccountSettingManager) {
        self.appConfigProvider = appConfigProvider
        self.accountSettingManager = accountSettingManager
    }

    var explorerApiKey: String {
        appConfigProvider.etherscanKey
    }

    var evmNetworkObservable: Observable<(Account, EvmNetwork)> {
        accountSettingManager.ethereumNetworkObservable
    }

    func evmNetwork(account: Account) -> EvmNetwork {
        accountSettingManager.ethereumNetwork(account: account)
    }

}

class BscKitManagerDataSource: IEvmKitManagerDataSource {
    private let appConfigProvider: AppConfigProvider
    private let accountSettingManager: AccountSettingManager

    init(appConfigProvider: AppConfigProvider, accountSettingManager: AccountSettingManager) {
        self.appConfigProvider = appConfigProvider
        self.accountSettingManager = accountSettingManager
    }

    var explorerApiKey: String {
        appConfigProvider.bscscanKey
    }

    var evmNetworkObservable: Observable<(Account, EvmNetwork)> {
        accountSettingManager.binanceSmartChainNetworkObservable
    }

    func evmNetwork(account: Account) -> EvmNetwork {
        accountSettingManager.binanceSmartChainNetwork(account: account)
    }

}
