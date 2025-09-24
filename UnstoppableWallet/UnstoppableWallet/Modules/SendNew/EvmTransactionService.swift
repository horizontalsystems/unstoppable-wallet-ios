import Combine
import EvmKit
import MarketKit
import SwiftUI

class EvmTransactionService: ITransactionService {
    private static let tipsSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))
    private static let legacyGasPriceSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))

    private let evmKit: EvmKit.Kit
    private let blockchainType: BlockchainType
    private let chain: Chain
    private let rpcSource: RpcSource
    private let networkManager = Core.shared.networkManager

    private let updateSubject = PassthroughSubject<Void, Never>()

    private(set) var usingRecommendedGasPrice: Bool = true
    private(set) var recommendedGasPrice: GasPrice?
    private(set) var gasPrice: GasPrice? {
        didSet {
            validate()
        }
    }

    private(set) var usingRecommendedNonce: Bool = true
    private(set) var minimumNonce: Int?
    private(set) var nextNonce: Int?
    private(set) var nonce: Int? {
        didSet {
            validate()
        }
    }

    private(set) var warnings: [Warning] = []
    private(set) var errors: [Error] = []

    var modified: Bool {
        !(usingRecommendedGasPrice && usingRecommendedNonce)
    }

    var cautions: [CautionNew] {
        var cautions = [CautionNew]()

        for warning in warnings {
            cautions.append(warning.caution)
        }

        if let error = errors.first {
            if let error = error as? NonceService.NonceError {
                cautions.append(error.caution)
            } else {
                cautions.append(CautionNew(title: "Error", text: "Nonce ERROR", type: .error))
            }
        }

        return cautions
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    var transactionSettings: TransactionSettings? {
        guard let gasPrice, let recommendedGasPrice else {
            return nil
        }

        return .evm(
            gasPriceData: GasPriceData(recommended: recommendedGasPrice, userDefined: gasPrice),
            nonce: usingRecommendedNonce ? nil : nonce
        )
    }

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
                usingRecommendedGasPrice = false
                self.gasPrice = gasPrice
            }

            if let nonce {
                usingRecommendedNonce = false
                self.nonce = nonce
            }
        }
    }

    private func validate() {
        var warnings = [Warning]()
        var errors = [Error]()

        switch (recommendedGasPrice, gasPrice) {
        case (let .eip1559(recommendedMaxFee, recommendedTips), let .eip1559(maxFee, tips)):
            let recommendedBaseFee = recommendedMaxFee - recommendedTips
            let actualTips = min(maxFee - recommendedBaseFee, tips)
            let tipsSafeRange = Self.tipsSafeRangeBounds.range(around: recommendedTips)

            if actualTips < tipsSafeRange.lowerBound {
                warnings.append(EvmFeeModule.GasDataWarning.riskOfGettingStuck)
            }

            if actualTips > tipsSafeRange.upperBound {
                warnings.append(EvmFeeModule.GasDataWarning.overpricing)
            }
        case let (.legacy(_recommendedGasPrice), .legacy(_gasPrice)):
            let gasPriceSafeRange = Self.legacyGasPriceSafeRangeBounds.range(around: _recommendedGasPrice)

            if _gasPrice < gasPriceSafeRange.lowerBound {
                warnings.append(EvmFeeModule.GasDataWarning.riskOfGettingStuck)
            }

            if _gasPrice > gasPriceSafeRange.upperBound {
                warnings.append(EvmFeeModule.GasDataWarning.overpricing)
            }
        default: ()
        }

        if let nonce, let minimumNonce, nonce < minimumNonce {
            errors.append(NonceService.NonceError.alreadyInUse)
        }

        self.warnings = warnings
        self.errors = errors
    }

    func sync() async throws {
        if chain.isEIP1559Supported {
            recommendedGasPrice = try await EIP1559GasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        } else {
            recommendedGasPrice = try await LegacyGasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        }

        if usingRecommendedGasPrice {
            gasPrice = recommendedGasPrice
        }

        minimumNonce = try await evmKit.nonce(defaultBlockParameter: .latest)
        nextNonce = try await evmKit.nonce(defaultBlockParameter: .pending)
        if usingRecommendedNonce {
            nonce = nextNonce
        }
    }

    var isEIP1559Supported: Bool {
        chain.isEIP1559Supported
    }

    func set(gasPrice: GasPrice) {
        self.gasPrice = gasPrice
        usingRecommendedGasPrice = (gasPrice == recommendedGasPrice)

        updateSubject.send()
    }

    func set(nonce: Int) {
        self.nonce = nonce
        usingRecommendedNonce = (nonce == nextNonce)

        updateSubject.send()
    }

    func useRecommended() {
        usingRecommendedGasPrice = true
        usingRecommendedNonce = true
        nonce = nextNonce
        gasPrice = recommendedGasPrice
        updateSubject.send()
    }
}
