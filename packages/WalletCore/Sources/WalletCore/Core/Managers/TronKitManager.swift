import Foundation
import HdWalletKit
import MarketKit
import RxRelay
import RxSwift
import TronKit

class TronKitManager {
    private let disposeBag = DisposeBag()
    private let testNetManager: TestNetManager
    private let evmSyncSourceManager: EvmSyncSourceManager

    private weak var _tronKitWrapper: TronKitWrapper?

    private let tronKitCreatedRelay = PublishRelay<Void>()
    private let tronKitUpdatedRelay = PublishRelay<Void>()
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).tron-kit-manager", qos: .userInitiated)

    init(testNetManager: TestNetManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.testNetManager = testNetManager
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] blockchainType in
            self?.handleUpdatedSyncSource(blockchainType: blockchainType)
        }
    }

    private func handleUpdatedSyncSource(blockchainType: BlockchainType) {
        guard blockchainType == .tron else { return }
        queue.sync {
            guard _tronKitWrapper != nil else { return }
            _tronKitWrapper = nil
            tronKitUpdatedRelay.accept(())
        }
    }

    private func rpcSource(network: Network, syncSource: EvmSyncSource) -> TronKit.RpcSource {
        if syncSource.rpcSource.url.absoluteString.contains("trongrid") {
            return .tronGrid(network: network, apiKeys: AppConfig.tronGridApiKeys)
        }

        let auth: String?
        if case let .http(_, a) = syncSource.rpcSource {
            auth = a
        } else {
            auth = nil
        }

        return TronKit.RpcSource(urls: [syncSource.rpcSource.url], apiKeys: [], auth: auth)
    }

    private func _tronKitWrapper(account: Account) throws -> TronKitWrapper {
        if let _tronKitWrapper, let currentAccount, currentAccount == account {
            return _tronKitWrapper
        }

        let network: Network = testNetManager.testNetEnabled ? .nileTestnet : .mainNet
        let address = try AccountAddress.tronAddress(account: account)
        var signer: Signer?

        switch account.type {
        case .mnemonic:
            guard let seed = account.type.mnemonicSeed else {
                throw KitWrapperError.mnemonicNoSeed
            }
            signer = try Signer.instance(seed: seed)
        case let .trcPrivateKey(data):
            signer = try Signer.instance(privateKey: data)
        case .tronAddress:
            ()
        case .passkeyOwned:
            // Watch-mode: address comes from GasFreeProfile (see AccountAddress.tronAddress).
            // Sends go via GasFree submitTransfer, not TronKit.send — signer stays nil.
            ()
        default:
            throw AdapterError.unsupportedAccount
        }
        let syncSource = evmSyncSourceManager.syncSource(blockchainType: .tron)
        let gaslessAccount = SmartAccountManager.isGasTokenPayment(account.type)
        let tronKit = try TronKit.Kit.instance(
            address: address,
            network: network,
            walletId: account.id,
            rpcSource: rpcSource(network: network, syncSource: syncSource),
            transactionSource: .tronGrid(network: network, apiKeys: AppConfig.tronGridApiKeys),
            minLogLevel: .error,
            gaslessAccount: gaslessAccount
        )

        tronKit.start()

        let wrapper = TronKitWrapper(
            tronKit: tronKit,
            signer: signer,
            gasTokenPayment: gaslessAccount
        )

        _tronKitWrapper = wrapper
        currentAccount = account

        tronKitCreatedRelay.accept(())

        return wrapper
    }
}

extension TronKitManager {
    var tronKitCreatedObservable: Observable<Void> {
        tronKitCreatedRelay.asObservable()
    }

    var tronKitUpdatedObservable: Observable<Void> {
        tronKitUpdatedRelay.asObservable()
    }

    var tronKitWrapper: TronKitWrapper? {
        queue.sync {
            _tronKitWrapper
        }
    }

    func tronKitWrapper(account: Account) throws -> TronKitWrapper {
        try queue.sync {
            try _tronKitWrapper(account: account)
        }
    }
}

class TronKitWrapper {
    let tronKit: TronKit.Kit
    let signer: Signer?
    /// True when this wrapper serves a gas-token-payment account (currently passkey-AA / GasFree).
    /// UI uses it to bypass on-chain `accountActive == false` cosmetic ("not activated") for accounts
    /// whose wallet is a CREATE2 BeaconProxy not yet deployed on chain.
    let gasTokenPayment: Bool

    init(tronKit: TronKit.Kit, signer: Signer?, gasTokenPayment: Bool) {
        self.tronKit = tronKit
        self.signer = signer
        self.gasTokenPayment = gasTokenPayment
    }

    @discardableResult
    func send(contract: Contract, feeLimit: Int?) async throws -> CreatedTransactionResponse {
        guard let signer else {
            throw SignerError.signerNotSupported
        }

        return try await tronKit.send(contract: contract, signer: signer, feeLimit: feeLimit)
    }

    func send(createdTranaction: CreatedTransactionResponse) async throws {
        guard let signer else {
            throw SignerError.signerNotSupported
        }

        try await tronKit.send(createdTransaction: createdTranaction, signer: signer)
    }
}

extension TronKitManager {
    enum KitWrapperError: Error {
        case mnemonicNoSeed
    }
}

extension TronKitWrapper {
    enum SignerError: Error {
        case signerNotSupported
    }
}
