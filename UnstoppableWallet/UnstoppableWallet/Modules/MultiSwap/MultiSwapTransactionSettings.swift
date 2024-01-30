import EvmKit
import Foundation
import MarketKit
import SwiftUI

enum MultiSwapTransactionSettings {
    case evm(gasPrice: GasPrice, nonce: Int)
    case bitcoin(satoshiPerByte: Int)
}

enum MultiSwapFeeQuote {
    case evm(gasLimit: Int)
    case bitcoin(bytes: Int)
}

protocol IMultiSwapTransactionService {
    var transactionSettings: MultiSwapTransactionSettings? { get }
    var modified: Bool { get }
    func sync() async throws
    func fee(quote: MultiSwapFeeQuote, token: Token) -> CoinValue?
    func settingsView() -> AnyView?
}

class EvmMultiSwapTransactionService: IMultiSwapTransactionService {
    private static let tipsSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))

    private let userAddress: EvmKit.Address
    private let blockchainType: BlockchainType
    private let chain: Chain
    private let rpcSource: RpcSource
    private let networkManager = App.shared.networkManager

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

    var transactionSettings: MultiSwapTransactionSettings? {
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

        if case let .eip1559(recommendedMaxFee, recommendedTips) = recommendedGasPrice,
           case let .eip1559(maxFee, tips) = gasPrice {
            let recommendedBaseFee = recommendedMaxFee - recommendedTips
            let actualTips = min(maxFee - recommendedBaseFee, tips)
            let tipsSafeRange = Self.tipsSafeRangeBounds.range(around: recommendedTips)

            if actualTips < tipsSafeRange.lowerBound {
                warnings.append(EvmFeeModule.GasDataWarning.riskOfGettingStuck)
            }

            if actualTips > tipsSafeRange.upperBound {
                warnings.append(EvmFeeModule.GasDataWarning.overpricing)
            }

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

    func fee(quote: MultiSwapFeeQuote, token: Token) -> CoinValue? {
        guard let gasPrice, case let .evm(gasLimit) = quote else {
            return nil
        }

        let amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, token.decimals)

        return CoinValue(kind: .token(token: token), value: amount)
    }

    func settingsView() -> AnyView? {
        if chain.isEIP1559Supported {
            let view = Eip1559FeeSettingsView(service: self, feeViewItemFactory: FeeViewItemFactory(scale: blockchainType.feePriceScale))
            return AnyView(ThemeNavigationView { view })
        } else {
            return AnyView(LegacyFeeSettingsView())
        }
    }

    func set(gasPrice: GasPrice) {
        self.gasPrice = gasPrice
        usingRecommendedGasPrice = (gasPrice == recommendedGasPrice)
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
    }
}
