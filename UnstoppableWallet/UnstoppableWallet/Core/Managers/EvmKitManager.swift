import RxSwift
import RxRelay
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit
import HdWalletKit

class EvmKitManager {
    let chain: Chain
    private let syncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    private weak var _evmKitWrapper: EvmKitWrapper?

    private let evmKitCreatedRelay = PublishRelay<Void>()
    private let evmKitUpdatedRelay = PublishRelay<Void>()
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.ethereum-kit-manager", qos: .userInitiated)

    init(chain: Chain, syncSourceManager: EvmSyncSourceManager) {
        self.chain = chain
        self.syncSourceManager = syncSourceManager

        subscribe(disposeBag, syncSourceManager.syncSourceObservable) { [weak self] account, blockchain, _ in
            self?.handleUpdatedSyncSource(account: account, blockchain: blockchain)
        }
    }

    private func handleUpdatedSyncSource(account: Account, blockchain: EvmBlockchain) {
        queue.sync {
            guard let _evmKitWrapper = _evmKitWrapper else {
                return
            }

            guard account == currentAccount, _evmKitWrapper.blockchain == blockchain else {
                return
            }

            self._evmKitWrapper = nil
            evmKitUpdatedRelay.accept(())
        }
    }

    private func _evmKitWrapper(account: Account, blockchain: EvmBlockchain) throws -> EvmKitWrapper {
        if let _evmKitWrapper = _evmKitWrapper, let currentAccount = currentAccount, currentAccount == account {
            return _evmKitWrapper
        }

        let syncSource = syncSourceManager.syncSource(account: account, blockchain: blockchain)

        let address: EthereumKit.Address
        var signer: Signer?

        switch account.type {
        case let .mnemonic(words, salt):
            let seed = Mnemonic.seed(mnemonic: words, passphrase: salt)
            address = try Signer.address(seed: seed, chain: chain)
            signer = try Signer.instance(seed: seed, chain: chain)
        case let .address(value):
            address = value
        default:
            throw AdapterError.unsupportedAccount
        }

        let evmKit = try EthereumKit.Kit.instance(
                address: address,
                chain: chain,
                rpcSource: syncSource.rpcSource,
                transactionSource: syncSource.transactionSource,
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

        let wrapper = EvmKitWrapper(blockchain: blockchain, evmKit: evmKit, signer: signer)

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

    func evmKitWrapper(account: Account, blockchain: EvmBlockchain) throws -> EvmKitWrapper {
        try queue.sync { try _evmKitWrapper(account: account, blockchain: blockchain)  }
    }

}

class EvmKitWrapper {
    let blockchain: EvmBlockchain
    let evmKit: EthereumKit.Kit
    let signer: Signer?

    init(blockchain: EvmBlockchain, evmKit: EthereumKit.Kit, signer: Signer?) {
        self.blockchain = blockchain
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
