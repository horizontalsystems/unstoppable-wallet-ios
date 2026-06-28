import BigInt
import Eip20Kit
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import OneInchKit
import RxRelay
import RxSwift
import UniswapKit

public class EvmKitManager {
    let chain: Chain
    private let syncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    private weak var _evmKitWrapper: EvmKitWrapper?

    private let evmKitCreatedRelay = PublishRelay<Void>()
    private let evmKitUpdatedRelay = PublishRelay<Void>()
    private(set) var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).ethereum-kit-manager", qos: .userInitiated)

    init(chain: Chain, syncSourceManager: EvmSyncSourceManager) {
        self.chain = chain
        self.syncSourceManager = syncSourceManager

        subscribe(disposeBag, syncSourceManager.syncSourceObservable) { [weak self] blockchainType in
            self?.handleUpdatedSyncSource(blockchainType: blockchainType)
        }
    }

    private func handleUpdatedSyncSource(blockchainType: BlockchainType) {
        queue.sync {
            guard let _evmKitWrapper else {
                return
            }

            guard _evmKitWrapper.blockchainType == blockchainType else {
                return
            }

            self._evmKitWrapper = nil
            evmKitUpdatedRelay.accept(())
        }
    }

    private func _evmKitWrapper(account: Account, blockchainType: BlockchainType) throws -> EvmKitWrapper {
        if let _evmKitWrapper, let currentAccount, currentAccount == account {
            return _evmKitWrapper
        }

        let syncSource = syncSourceManager.syncSource(blockchainType: blockchainType)

        let address = try AccountAddress.evmAddress(account: account, blockchainType: blockchainType)
        var signer: Signer?

        switch account.type {
        case .mnemonic:
            guard let seed = account.type.mnemonicSeed else {
                throw KitWrapperError.mnemonicNoSeed
            }
            signer = try Signer.instance(seed: seed, chain: chain)
        case let .evmPrivateKey(data):
            signer = Signer.instance(privateKey: data, chain: chain)
        case .evmAddress, .passkeyOwned:
            ()
        default:
            throw AdapterError.unsupportedAccount
        }

        let evmKit = try EvmKit.Kit.instance(
            address: address,
            chain: chain,
            rpcSource: syncSource.rpcSource,
            transactionSource: syncSource.transactionSource,
            walletId: account.id,
            minLogLevel: .error
        )

        evmKit.set(syncers: EvmKitConfigFactory.syncers(account: account, evmKit: evmKit))
        EvmKitConfigFactory.applyDecorators(account: account, evmKit: evmKit)

        var merkleTransactionAdapter: MerkleTransactionAdapter?
        if signer != nil,
           let merkleAdapter = MerkleTransactionAdapter(
               transactionManager: evmKit.transactionManager,
               address: address,
               chain: chain,
               walletId: account.id,
               logger: nil
           )
        {
            evmKit.add(nonceProvider: merkleAdapter.blockchain)
            evmKit.add(transactionSyncer: merkleAdapter.syncer)
            evmKit.add(extraDecorator: merkleAdapter.syncer)

            merkleTransactionAdapter = merkleAdapter
        }

        evmKit.start()

        let wrapper = EvmKitWrapper(
            blockchainType: blockchainType,
            evmKit: evmKit,
            merkleTransactionAdapter: merkleTransactionAdapter,
            signer: signer
        )

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
        queue.sync {
            _evmKitWrapper
        }
    }

    public func evmKitWrapper(account: Account, blockchainType: BlockchainType) throws -> EvmKitWrapper {
        try queue.sync {
            try _evmKitWrapper(account: account, blockchainType: blockchainType)
        }
    }
}

public class EvmKitWrapper {
    let blockchainType: BlockchainType
    public let evmKit: EvmKit.Kit
    let merkleTransactionAdapter: MerkleTransactionAdapter?
    let signer: Signer?

    init(blockchainType: BlockchainType, evmKit: EvmKit.Kit, merkleTransactionAdapter: MerkleTransactionAdapter?, signer: Signer?) {
        self.blockchainType = blockchainType
        self.evmKit = evmKit
        self.merkleTransactionAdapter = merkleTransactionAdapter
        self.signer = signer
    }

    var mevProtectionEnabled: Bool {
        merkleTransactionAdapter != nil
    }

    func sendSingle(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, privateSend _: Bool, nonce: Int? = nil) -> Single<FullTransaction> {
        guard let signer else {
            return Single.error(SignerError.signerNotSupported)
        }

        return evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
            .flatMap { [weak self] rawTransaction in
                guard let strongSelf = self else {
                    return Single.error(AppError.weakReference)
                }

                do {
                    let signature = try signer.signature(rawTransaction: rawTransaction)
                    return strongSelf.evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                } catch {
                    return Single.error(error)
                }
            }
    }

    func sendCancel(hash: Data) async throws -> Bool {
        guard let merkleTransactionAdapter else {
            throw MerkleAdapterError.MerkleAdapterNotSupported
        }

        return try await merkleTransactionAdapter.cancel(hash: hash)
    }

    func send(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, privateSend: Bool, nonce: Int? = nil) async throws -> FullTransaction {
        guard let signer else {
            throw SignerError.signerNotSupported
        }

        let rawTransaction = try await evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
        let signature = try signer.signature(rawTransaction: rawTransaction)

        if privateSend, let merkleTransactionAdapter {
            return try await merkleTransactionAdapter.send(rawTransaction: rawTransaction, signature: signature)
        }

        return try await evmKit.send(rawTransaction: rawTransaction, signature: signature)
    }
}

extension EvmKitManager {
    enum KitWrapperError: Error {
        case mnemonicNoSeed
    }
}

extension EvmKitWrapper {
    enum SignerError: Error {
        case signerNotSupported
    }

    enum MerkleAdapterError: Error {
        case MerkleAdapterNotSupported
    }

    public enum DecorationError: Error {
        case cantCreateDecoration
    }
}
