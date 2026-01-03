import Combine
import EvmKit
import MarketKit
import SwiftUI

class EvmTransactionService {
    private static let tipsSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))
    private static let legacyGasPriceSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))

    private let evmKit: EvmKit.Kit
    private let blockchainType: BlockchainType
    private let chain: Chain
    private let rpcSource: RpcSource
    private let networkManager = Core.shared.networkManager

    private let updateSubject = PassthroughSubject<Void, Never>()

    private(set) var recommendedGasPrice: GasPrice?
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

    init?(blockchainType: BlockchainType, evmKit: EvmKit.Kit, initialTransactionSettings: InitialTransactionSettings?) {
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType),
              let rpcSource = Core.shared.evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource
        else {
            return nil
        }

        self.chain = chain
        self.blockchainType = blockchainType
        self.evmKit = evmKit
        self.rpcSource = rpcSource

        if case let .evm(gasPrice, nonce) = initialTransactionSettings {
            if let gasPrice {
                self.gasPrice = gasPrice
            }

            if let nonce {
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
        guard let recommendedGasPrice else {
            return nil
        }

        return .evm(
            gasPriceData: GasPriceData(recommended: recommendedGasPrice, userDefined: gasPrice ?? recommendedGasPrice),
            nonce: nonce
        )
    }

    var modified: Bool {
        gasPrice != nil || nonce != nil
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
            recommendedGasPrice = try await EIP1559GasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        } else {
            recommendedGasPrice = try await LegacyGasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        }

        minimumNonce = try await evmKit.nonce(defaultBlockParameter: .latest)
        nextNonce = try await evmKit.nonce(defaultBlockParameter: .pending)
    }
}

extension EvmTransactionService {
    var isEIP1559Supported: Bool {
        chain.isEIP1559Supported
    }

    var currentGasPrice: GasPrice? {
        gasPrice ?? recommendedGasPrice
    }

    var currentNonce: Int? {
        nonce ?? nextNonce
    }

    func set(gasPrice: GasPrice?) {
        self.gasPrice = gasPrice
        updateSubject.send()
    }

    func set(nonce: Int?) {
        self.nonce = nonce
        updateSubject.send()
    }
}

extension EvmTransactionService {
    static func validateGasPrice(recommended: GasPrice?, current: GasPrice?) -> [EvmFeeModule.GasDataWarning] {
        var warnings = [EvmFeeModule.GasDataWarning]()

        switch (recommended, current) {
        case (let .eip1559(recommendedMaxFee, recommendedTips), let .eip1559(maxFee, tips)):
            let recommendedBaseFee = recommendedMaxFee - recommendedTips
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
