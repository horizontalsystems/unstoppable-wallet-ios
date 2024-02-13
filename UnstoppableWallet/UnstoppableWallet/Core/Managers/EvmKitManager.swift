import Eip20Kit
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import NftKit
import OneInchKit
import RxRelay
import RxSwift
import UniswapKit

class EvmKitManager {
    let chain: Chain
    private let syncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    private weak var _evmKitWrapper: EvmKitWrapper?

    private let evmKitCreatedRelay = PublishRelay<Void>()
    private let evmKitUpdatedRelay = PublishRelay<Void>()
    private var currentAccount: Account?

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

        let address: EvmKit.Address
        var signer: Signer?

        switch account.type {
        case .mnemonic:
            guard let seed = account.type.mnemonicSeed else {
                throw KitWrapperError.mnemonicNoSeed
            }
            address = try Signer.address(seed: seed, chain: chain)
            signer = try Signer.instance(seed: seed, chain: chain)
        case let .evmPrivateKey(data):
            address = Signer.address(privateKey: data)
            signer = Signer.instance(privateKey: data, chain: chain)
        case let .evmAddress(value):
            address = value
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

        Eip20Kit.Kit.addDecorators(to: evmKit)
        Eip20Kit.Kit.addTransactionSyncer(to: evmKit)

        var nftKit: NftKit.Kit?
        let supportedNftTypes = blockchainType.supportedNftTypes

        if !supportedNftTypes.isEmpty {
            let kit = try NftKit.Kit.instance(evmKit: evmKit)

            for nftType in supportedNftTypes {
                switch nftType {
                case .eip721:
                    kit.addEip721TransactionSyncer()
                    kit.addEip721Decorators()
                case .eip1155:
                    kit.addEip1155TransactionSyncer()
                    kit.addEip1155Decorators()
                }
            }

            nftKit = kit
        }

        UniswapKit.Kit.addDecorators(to: evmKit)
        try? KitV3.addDecorators(to: evmKit)
        OneInchKit.Kit.addDecorators(to: evmKit)

        evmKit.start()

        let wrapper = EvmKitWrapper(blockchainType: blockchainType, evmKit: evmKit, nftKit: nftKit, signer: signer)

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

    func evmKitWrapper(account: Account, blockchainType: BlockchainType) throws -> EvmKitWrapper {
        try queue.sync {
            try _evmKitWrapper(account: account, blockchainType: blockchainType)
        }
    }
}

class EvmKitWrapper {
    let blockchainType: BlockchainType
    let evmKit: EvmKit.Kit
    let nftKit: NftKit.Kit?
    let signer: Signer?

    init(blockchainType: BlockchainType, evmKit: EvmKit.Kit, nftKit: NftKit.Kit?, signer: Signer?) {
        self.blockchainType = blockchainType
        self.evmKit = evmKit
        self.nftKit = nftKit
        self.signer = signer
    }

    func sendSingle(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<FullTransaction> {
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

    func send(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) async throws -> FullTransaction {
        guard let signer else {
            throw SignerError.signerNotSupported
        }

        let rawTransaction = try await evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
        let signature = try signer.signature(rawTransaction: rawTransaction)
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
}
