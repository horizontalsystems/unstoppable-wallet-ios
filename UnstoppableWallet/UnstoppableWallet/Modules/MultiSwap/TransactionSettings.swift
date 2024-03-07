import Combine
import EvmKit
import Foundation
import MarketKit
import SwiftUI

enum TransactionSettings {
    case evm(gasPrice: GasPrice, nonce: Int)
    case bitcoin(satoshiPerByte: Int)

    var gasPrice: GasPrice? {
        switch self {
        case let .evm(gasPrice, _): return gasPrice
        default: return nil
        }
    }

    var nonce: Int? {
        switch self {
        case let .evm(_, nonce): return nonce
        default: return nil
        }
    }
}

enum FeeData {
    case evm(gasLimit: Int)
    case bitcoin(bytes: Int)

    var gasLimit: Int? {
        switch self {
        case let .evm(gasLimit): return gasLimit
        default: return nil
        }
    }
}

protocol ITransactionService {
    var transactionSettings: TransactionSettings? { get }
    var modified: Bool { get }
    var cautions: [CautionNew] { get }
    var updatePublisher: AnyPublisher<Void, Never> { get }
    func sync() async throws
    func settingsView(feeData: Binding<FeeData?>, loading: Binding<Bool>, feeToken: Token, currency: Currency, feeTokenRate: Binding<Decimal?>) -> AnyView?
}

class EvmTransactionService: ITransactionService {
    private static let tipsSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))
    private static let legacyGasPriceSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))

    private let userAddress: EvmKit.Address
    private let blockchainType: BlockchainType
    private let chain: Chain
    private let rpcSource: RpcSource
    private let networkManager = App.shared.networkManager

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
            cautions.append(.init(title: warning.titledCaution.title, text: warning.titledCaution.text, type: warning.titledCaution.type))
        }

        for error in errors {
            cautions.append(.init(text: error.smartDescription, type: .error))
        }

        return cautions
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    var transactionSettings: TransactionSettings? {
        guard let gasPrice, let nonce else {
            return nil
        }

        return .evm(gasPrice: gasPrice, nonce: nonce)
    }

    init?(blockchainType: BlockchainType, userAddress: EvmKit.Address) {
        guard let rpcSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            return nil
        }

        chain = App.shared.evmBlockchainManager.chain(blockchainType: blockchainType)
        self.blockchainType = blockchainType
        self.userAddress = userAddress
        self.rpcSource = rpcSource
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

        nextNonce = try await EvmKit.Kit.nonceSingle(networkManager: networkManager, rpcSource: rpcSource, userAddress: userAddress, defaultBlockParameter: .latest)
        minimumNonce = try await EvmKit.Kit.nonceSingle(networkManager: networkManager, rpcSource: rpcSource, userAddress: userAddress, defaultBlockParameter: .pending)

        if usingRecommendedNonce {
            nonce = nextNonce
        }
    }

    func settingsView(feeData: Binding<FeeData?>, loading: Binding<Bool>, feeToken: Token, currency: Currency, feeTokenRate: Binding<Decimal?>) -> AnyView? {
        if chain.isEIP1559Supported {
            let viewModel = Eip1559FeeSettingsViewModel(service: self, feeViewItemFactory: FeeViewItemFactory(scale: blockchainType.feePriceScale))
            let view = Eip1559FeeSettingsView(
                viewModel: viewModel,
                feeData: feeData,
                loading: loading,
                feeToken: feeToken,
                currency: currency,
                feeTokenRate: feeTokenRate
            )
            return AnyView(ThemeNavigationView { view })
        } else {
            let viewModel = LegacyFeeSettingsViewModel(service: self, feeViewItemFactory: FeeViewItemFactory(scale: blockchainType.feePriceScale))
            let view = LegacyFeeSettingsView(
                viewModel: viewModel,
                feeData: feeData,
                loading: loading,
                feeToken: feeToken,
                currency: currency,
                feeTokenRate: feeTokenRate
            )
            return AnyView(ThemeNavigationView { view })
        }
    }

    func set(gasPrice: GasPrice) {
        self.gasPrice = gasPrice
        usingRecommendedGasPrice = (gasPrice == recommendedGasPrice)

        updateSubject.send()
    }

    func set(nonce: Int) {
        self.nonce = nonce
        usingRecommendedNonce = (nonce == nextNonce)
    }

    func useRecommended() {
        usingRecommendedGasPrice = true
        usingRecommendedNonce = true
        nonce = nextNonce
        gasPrice = recommendedGasPrice
        updateSubject.send()
    }
}
