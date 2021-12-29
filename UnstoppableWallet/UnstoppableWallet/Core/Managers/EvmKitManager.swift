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

    private weak var _evmKitWrapper: EvmKitWrapper?

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

            _evmKitWrapper = nil
            evmKitUpdatedRelay.accept(())
        }
    }

    private func _evmKitWrapper(account: Account) throws -> EvmKitWrapper {
        if let _evmKitWrapper = _evmKitWrapper, let currentAccount = currentAccount, currentAccount == account {
            return _evmKitWrapper
        }

        guard let seed = account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let evmNetwork = dataSource.evmNetwork(account: account)

        let address = try Signer.address(seed: seed, networkType: evmNetwork.networkType)
        let signer = try Signer.instance(seed: seed, networkType: evmNetwork.networkType)

        let evmKit = try EthereumKit.Kit.instance(
                address: address,
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

        let wrapper = EvmKitWrapper(evmKit: evmKit, signer: signer)

        _evmKitWrapper = wrapper
        currentAccount = account

        return wrapper
    }

}

extension EvmKitManager {

    var evmKitUpdatedObservable: Observable<Void> {
        evmKitUpdatedRelay.asObservable()
    }

    var evmKitWrapper: EvmKitWrapper? {
        queue.sync { _evmKitWrapper }
    }

    func evmKit(account: Account) throws -> EthereumKit.Kit {
        try queue.sync { try _evmKitWrapper(account: account).evmKit  }
    }

    func evmKitWrapper(account: Account) throws -> EvmKitWrapper {
        try queue.sync { try _evmKitWrapper(account: account)  }
    }

    func signer(account: Account) throws -> Signer {
        try queue.sync { try _evmKitWrapper(account: account).signer  }
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

class EvmKitWrapper {
    let evmKit: EthereumKit.Kit
    let signer: Signer

    init(evmKit: EthereumKit.Kit, signer: Signer) {
        self.evmKit = evmKit
        self.signer = signer
    }

    func sendSingle(transactionData: TransactionData, gasPrice: Int, gasLimit: Int, nonce: Int? = nil) -> Single<FullTransaction> {
        evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
                .flatMap { [unowned self] rawTransaction in
                    do {
                        let signature = try signer.signature(rawTransaction: rawTransaction)
                        return evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                    } catch {
                        return Single.error(error)
                    }
                }
    }

}
