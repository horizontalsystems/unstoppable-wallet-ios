import Combine
import EvmKit
import HsToolKit
import MarketKit
import SwiftUI

class EvmTransactionService: TransactionService {
    override class func instance(sendData: SendData, baseToken: Token, initialTransactionSettings: InitialTransactionSettings?) -> ITransactionService? {
        guard EvmBlockchainManager.blockchainTypes.contains(baseToken.blockchainType),
              let evmKit = try? Core.shared.evmBlockchainManager.evmKitManager(blockchainType: baseToken.blockchainType).evmKitWrapper?.evmKit
        else { return nil }

        if case let .evmResend(blockchainType, transaction, _) = sendData {
            guard blockchainType == baseToken.blockchainType, transaction.from == evmKit.receiveAddress, transaction.nonce != nil else { return nil }
            return EvmTransactionService(blockchainType: blockchainType, evmKit: evmKit, initialTransactionSettings: initialTransactionSettings, previousTransaction: transaction)
        }

        return EvmTransactionService(blockchainType: baseToken.blockchainType, evmKit: evmKit, initialTransactionSettings: initialTransactionSettings)
    }

    private static let tipsSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))
    private static let legacyGasPriceSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))

    private let evmKit: EvmKit.Kit
    private let blockchainType: BlockchainType
    private let chain: Chain
    private let rpcSource: RpcSource
    private let previousTransaction: EvmKit.Transaction?
    private let networkManager = Core.shared.networkManager
//    private let networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))

    private let updateSubject = PassthroughSubject<Void, Never>()

    private var networkGasPrice: GasPrice?
    var recommendedGasPrice: GasPrice? { gasPriceData?.recommended }

    private var gasPriceData: GasPriceData? {
        networkGasPrice.map { Self.gasPriceData(network: $0, previousTransaction: previousTransaction, custom: gasPrice) }
    }

    private var gasPrice: GasPrice? {
        didSet {
            validateGasPrice()
        }
    }

    private(set) var minimumNonce: Int?
    private(set) var nextNonce: Int?
    private(set) var nonce: Int? {
        didSet {
            validateNonce()
        }
    }

    private var gasPriceWarnings: [EvmFeeModule.GasDataWarning] = []
    private var nonceErrors: [NonceService.NonceError] = []

    init?(blockchainType: BlockchainType, evmKit: EvmKit.Kit, initialTransactionSettings: InitialTransactionSettings?, previousTransaction: EvmKit.Transaction? = nil) {
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType),
              let rpcSource = Core.shared.evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource
        else {
            return nil
        }

        self.chain = chain
        self.blockchainType = blockchainType
        self.evmKit = evmKit
        self.rpcSource = rpcSource
        self.previousTransaction = previousTransaction
        nonce = previousTransaction?.nonce

        if case let .evm(gasPrice, nonce) = initialTransactionSettings {
            if let gasPrice {
                self.gasPrice = gasPrice
            }

            if let nonce, previousTransaction == nil {
                self.nonce = nonce
            }
        }
    }

    private func validateGasPrice() {
        gasPriceWarnings = Self.validateGasPrice(recommended: recommendedGasPrice, current: currentGasPrice)
    }

    private func validateNonce() {
        nonceErrors = Self.validateNonce(nonce: nonce, minimumNonce: minimumNonce)
    }
}

extension EvmTransactionService: ITransactionService {
    var transactionSettings: TransactionSettings? {
        guard let gasPriceData else {
            return nil
        }

        return .evm(
            gasPriceData: gasPriceData,
            nonce: nonce
        )
    }

    var modified: Bool {
        gasPrice != nil || (nonceEditable && nonce != nil)
    }

    var cautions: [CautionNew] {
        var cautions = [CautionNew]()

        for warning in gasPriceWarnings {
            cautions.append(warning.caution)
        }

        for error in nonceErrors {
            cautions.append(error.caution)
        }

        return cautions
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func sync() async throws {
        if isEIP1559Supported {
            networkGasPrice = try await EIP1559GasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        } else {
            networkGasPrice = try await LegacyGasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        }

        if let previousTransaction {
            nextNonce = previousTransaction.nonce
            validateGasPrice()
        } else {
            minimumNonce = try await evmKit.nonce(defaultBlockParameter: .latest)
            nextNonce = try await evmKit.nonce(defaultBlockParameter: .pending)
        }
    }
}

extension EvmTransactionService {
    var isEIP1559Supported: Bool {
        chain.isEIP1559Supported
    }

    var currentGasPrice: GasPrice? {
        gasPrice ?? gasPriceData?.userDefined
    }

    var defaultGasPrice: GasPrice? {
        networkGasPrice.map { Self.gasPriceData(network: $0, previousTransaction: previousTransaction, custom: nil).userDefined }
    }

    var nonceEditable: Bool {
        previousTransaction == nil
    }

    var currentNonce: Int? {
        nonce ?? nextNonce
    }

    func set(gasPrice: GasPrice?) {
        self.gasPrice = gasPrice
        updateSubject.send()
    }

    func set(nonce: Int?) {
        guard nonceEditable else { return }
        self.nonce = nonce
        updateSubject.send()
    }
}

extension EvmTransactionService {
    static func gasPriceData(network: GasPrice, previousTransaction: EvmKit.Transaction?, custom: GasPrice?) -> GasPriceData {
        let recommended: GasPrice
        let defaultPrice: GasPrice

        switch network {
        case let .legacy(gasPrice):
            recommended = .legacy(gasPrice: max(gasPrice, previousTransaction?.gasPrice ?? gasPrice))
            // Preserve LegacyGasPriceService: the recommendation is floored, the default selection is the network price.
            defaultPrice = network
        case let .eip1559(maxFee, tips):
            if let previousMaxFee = previousTransaction?.maxFeePerGas, let previousTips = previousTransaction?.maxPriorityFeePerGas {
                let recommendedTips = max(tips, previousTips)
                recommended = .eip1559(maxFeePerGas: max(maxFee - tips + recommendedTips, previousMaxFee), maxPriorityFeePerGas: recommendedTips)
            } else {
                recommended = network
            }
            defaultPrice = recommended
        }

        return GasPriceData(recommended: recommended, userDefined: custom ?? defaultPrice)
    }

    static func validateGasPrice(recommended: GasPrice?, current: GasPrice?) -> [EvmFeeModule.GasDataWarning] {
        var warnings = [EvmFeeModule.GasDataWarning]()

        switch (recommended, current) {
        case (let .eip1559(recommendedMaxFee, recommendedTips), let .eip1559(maxFee, tips)):
            let recommendedBaseFee = (recommendedMaxFee - recommendedTips) * 100 / GasPrice.eip1559SurchargeBasis
            let actualTips = min(maxFee - recommendedBaseFee, tips)
            let tipsSafeRange = Self.tipsSafeRangeBounds.range(around: recommendedTips)

            if actualTips < tipsSafeRange.lowerBound {
                warnings.append(.riskOfGettingStuck)
            }

            if actualTips > tipsSafeRange.upperBound {
                warnings.append(.overpricing)
            }
        case let (.legacy(_recommendedGasPrice), .legacy(_gasPrice)):
            let gasPriceSafeRange = Self.legacyGasPriceSafeRangeBounds.range(around: _recommendedGasPrice)

            if _gasPrice < gasPriceSafeRange.lowerBound {
                warnings.append(.riskOfGettingStuck)
            }

            if _gasPrice > gasPriceSafeRange.upperBound {
                warnings.append(.overpricing)
            }
        default: ()
        }

        return warnings
    }

    static func validateNonce(nonce: Int?, minimumNonce: Int?) -> [NonceService.NonceError] {
        if let nonce, let minimumNonce, nonce < minimumNonce {
            return [.alreadyInUse]
        } else {
            return []
        }
    }
}
