import UIKit
import BigInt
import EvmKit
import RxSwift
import RxCocoa
import ThemeKit

struct EvmFeeModule {

    static func viewController(feeViewModel: EvmFeeViewModel) -> UIViewController? {
        let feeService = feeViewModel.service
        let coinService = feeViewModel.coinService
        let gasPriceService = feeViewModel.gasPriceService
        let feeViewItemFactory = FeeViewItemFactory(scale: coinService.token.blockchainType.feePriceScale)
        let cautionsFactory = SendEvmCautionsFactory()

        switch gasPriceService {
        case let legacyService as LegacyGasPriceService:
            let viewModel = LegacyEvmFeeViewModel(gasPriceService: legacyService, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory, cautionsFactory: cautionsFactory)
            return ThemeNavigationController(rootViewController: LegacyEvmFeeViewController(viewModel: viewModel))

        case let eip1559Service as Eip1559GasPriceService:
            let viewModel = Eip1559EvmFeeViewModel(gasPriceService: eip1559Service, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory, cautionsFactory: cautionsFactory)
            return ThemeNavigationController(rootViewController: Eip1559EvmFeeViewController(viewModel: viewModel))

        default: return nil
        }
    }

    static func gasPriceService(evmKit: EvmKit.Kit, gasPrice: GasPrice? = nil, previousTransaction: EvmKit.Transaction? = nil) -> IGasPriceService {
        if evmKit.chain.isEIP1559Supported {
            var initialMaxBaseFee: Int? = nil
            var initialMaxTips: Int? = nil
            var minRecommendedBaseFee: Int? = nil
            var minRecommendedTips: Int? = nil

            if case .eip1559(let maxBaseFee, let maxTips) = gasPrice {
                initialMaxBaseFee = maxBaseFee
                initialMaxTips = maxTips
            }

            if let previousMaxFeePerGas = previousTransaction?.maxFeePerGas, let previousMaxPriorityFeePerGas = previousTransaction?.maxPriorityFeePerGas {
                minRecommendedBaseFee = previousMaxFeePerGas - previousMaxPriorityFeePerGas
                minRecommendedTips = previousMaxPriorityFeePerGas
            }

            return Eip1559GasPriceService(evmKit: evmKit, initialMaxBaseFee: initialMaxBaseFee, initialMaxTips: initialMaxTips, minRecommendedBaseFee: minRecommendedBaseFee, minRecommendedTips: minRecommendedTips)
        } else {
            var initialGasPrice: Int? = nil
            var minRecommendedGasPrice: Int? = nil

            if case .legacy(let gasPrice) = gasPrice {
                initialGasPrice = gasPrice
            }

            if let previousGasPrice = previousTransaction?.gasPrice {
                minRecommendedGasPrice = previousGasPrice
            }

            return LegacyGasPriceService(evmKit: evmKit, initialGasPrice: initialGasPrice, minRecommendedGasPrice: minRecommendedGasPrice)
        }
    }
}

extension EvmFeeModule {

    enum GasDataError: Error {
        case insufficientBalance
        case lowMaxFee
    }

    enum GasDataWarning: Warning {
        case riskOfGettingStuck
        case overpricing
    }

    class GasData {
        let limit: Int
        let price: GasPrice

        init(limit: Int, price: GasPrice) {
            self.limit = limit
            self.price = price
        }

        var fee: BigUInt {
            BigUInt(limit * price.max)
        }

        var description: String {
            "L1 transaction: gasLimit:\(limit) - gasPrice:\(price.description)"
        }
    }

    class RollupGasData: GasData {
        let additionalFee: BigUInt

        init(additionalFee: BigUInt, limit: Int, price: GasPrice) {
            self.additionalFee = additionalFee
            super.init(limit: limit, price: price)
        }

        override var fee: BigUInt {
            super.fee + additionalFee
        }

        override var description: String {
            "L2 transaction: gasLimit:\(limit) - gasPrice:\(price.description) - l1fee:\(additionalFee.description)"
        }
    }

    struct Transaction {
        let transactionData: TransactionData
        let gasData: GasData

        var totalAmount: BigUInt {
            transactionData.value + gasData.fee
        }
    }

}

protocol IEvmFeeService {
    var status: DataStatus<FallibleData<EvmFeeModule.Transaction>> { get }
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.Transaction>>> { get }
}

protocol IGasPriceService {
    var status: DataStatus<FallibleData<GasPrice>> { get }
    var statusObservable: Observable<DataStatus<FallibleData<GasPrice>>> { get }
    var usingRecommended: Bool { get }
}

struct RangeBounds {
    enum BoundType {
        case factor(Float)
        case distance(Int)
        case fixed(Int)
    }

    let lower: BoundType
    let upper: BoundType

    init(lower: BoundType, upper: BoundType) {
        self.lower = lower
        self.upper = upper
    }

    func range(around center: Int, containing selected: Int? = nil) -> ClosedRange<Int> {
        var lowerBound = 0
        var upperBound = 0

        switch lower {
        case .factor(let factor): lowerBound = Int(Float(center) * factor)
        case .distance(let distance): lowerBound = center - distance
        case .fixed(let value): lowerBound = value
        }

        lowerBound = max(lowerBound, 0)

        switch upper {
        case .factor(let factor): upperBound = Int(Float(center) * factor)
        case .distance(let distance): upperBound = center + distance
        case .fixed(let value): upperBound = value
        }

        if let selected = selected {
            lowerBound = min(lowerBound, selected)
            upperBound = max(upperBound, selected)
        }

        return lowerBound...upperBound
    }

}
