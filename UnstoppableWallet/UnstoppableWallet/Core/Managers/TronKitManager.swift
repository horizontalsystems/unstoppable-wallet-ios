import Foundation
import RxSwift
import RxRelay
import TronKit
import HdWalletKit
import MarketKit

class TronKitManager {
    private let disposeBag = DisposeBag()
    private let testNetManager: TestNetManager

    private weak var _tronKitWrapper: TronKitWrapper?

    private let tronKitCreatedRelay = PublishRelay<Void>()
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).tron-kit-manager", qos: .userInitiated)

    init(testNetManager: TestNetManager) {
        self.testNetManager = testNetManager
    }

    private func _tronKitWrapper(account: Account, blockchainType: BlockchainType) throws -> TronKitWrapper {
        if let _tronKitWrapper = _tronKitWrapper, let currentAccount = currentAccount, currentAccount == account {
            return _tronKitWrapper
        }

        let network: Network = testNetManager.testNetEnabled ? .nileTestnet : .mainNet
        let address: TronKit.Address
        var signer: Signer?

        switch account.type {
            case .mnemonic:
                guard let seed = account.type.mnemonicSeed else {
                    throw KitWrapperError.mnemonicNoSeed
                }
                address = try Signer.address(seed: seed)
                signer = try Signer.instance(seed: seed)
            case let .tronAddress(value):
                address = value
            default:
                throw AdapterError.unsupportedAccount
        }

        let tronKit = try TronKit.Kit.instance(
            address: address,
            network: network,
            walletId: account.id,
            apiKey: AppConfig.tronGridApiKey,
            minLogLevel: .error
        )

        tronKit.start()

        let wrapper = TronKitWrapper(blockchainType: blockchainType, tronKit: tronKit, signer: signer)

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

    var tronKitWrapper: TronKitWrapper? {
        queue.sync {
            _tronKitWrapper
        }
    }

    func tronKitWrapper(account: Account, blockchainType: BlockchainType) throws -> TronKitWrapper {
        try queue.sync {
            try _tronKitWrapper(account: account, blockchainType: blockchainType)
        }
    }

}

class TronKitWrapper {
    let blockchainType: BlockchainType
    let tronKit: TronKit.Kit
    let signer: Signer?

    init(blockchainType: BlockchainType, tronKit: TronKit.Kit, signer: Signer?) {
        self.blockchainType = blockchainType
        self.tronKit = tronKit
        self.signer = signer
    }

    func send(contract: Contract, feeLimit: Int?) async throws {
        guard let signer = signer else {
            throw SignerError.signerNotSupported
        }

        return try await tronKit.send(contract: contract, signer: signer, feeLimit: feeLimit)
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
