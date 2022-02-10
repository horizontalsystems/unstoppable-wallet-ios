import RxSwift
import RxRelay
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit
import HdWalletKit

protocol IEvmKitManagerDataSource {
    var explorerApiKey: String { get }
    var evmNetworkObservable: Observable<(Account, EvmNetwork)> { get }
    func evmNetwork(account: Account) -> EvmNetwork
}

class EvmKitManager {
    private let dataSource: IEvmKitManagerDataSource
    private let disposeBag = DisposeBag()

    private weak var _evmKitWrapper: EvmKitWrapper?

    private let evmKitCreatedRelay = PublishRelay<Void>()
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

        let evmNetwork = dataSource.evmNetwork(account: account)

        let address: EthereumKit.Address
        var signer: Signer?

        switch account.type {
        case let .mnemonic(words, salt):
            let seed = Mnemonic.seed(mnemonic: words, passphrase: salt)
            address = try Signer.address(seed: seed, networkType: evmNetwork.networkType)
            signer = try Signer.instance(seed: seed, networkType: evmNetwork.networkType)
        case let .address(value):
            address = value
        default:
            throw AdapterError.unsupportedAccount
        }

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

        evmKitCreatedRelay.accept(())

        return wrapper
    }

}

extension EvmKitManager {

    var evmKitCreatedObservable: Observable<Void> {
        evmKitCreatedRelay.asObservable()
    }

    var evmKitUpdatedObservable: Observable<Void> {
        evmKitUpdatedRelay.asObservable()
    }

    var evmKitWrapper: EvmKitWrapper? {
        queue.sync { _evmKitWrapper }
    }

    func evmKitWrapper(account: Account) throws -> EvmKitWrapper {
        try queue.sync { try _evmKitWrapper(account: account)  }
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
    let signer: Signer?

    init(evmKit: EthereumKit.Kit, signer: Signer?) {
        self.evmKit = evmKit
        self.signer = signer
    }

    func sendSingle(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<FullTransaction> {
        guard let signer = signer else {
            return Single.error(SignerError.signerNotSupported)
        }

        return evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
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

extension EvmKitWrapper {

    enum SignerError: Error {
        case signerNotSupported
    }

}
