import UIKit
import BigInt
import EvmKit
import RxSwift
import RxCocoa
import ThemeKit

struct EvmFeeModule {
    private static let surchargePercent: Double = 10

    static func surcharged(gasLimit: Int) -> Int {
        gasLimit + Int(Double(gasLimit) / 100.0 * surchargePercent)
    }

    static func gasPriceService(evmKit: EvmKit.Kit, gasPrice: GasPrice? = nil, previousTransaction: EvmKit.Transaction? = nil) -> IGasPriceService {
        if evmKit.chain.isEIP1559Supported {
            var initialMaxBaseFee: Int? = nil
            var initialMaxTips: Int? = nil
            var minRecommendedMaxFee: Int? = nil
            var minRecommendedTips: Int? = nil

            if case .eip1559(let maxBaseFee, let maxTips) = gasPrice {
                initialMaxBaseFee = maxBaseFee
                initialMaxTips = maxTips
            }

            if let previousMaxFeePerGas = previousTransaction?.maxFeePerGas, let previousMaxPriorityFeePerGas = previousTransaction?.maxPriorityFeePerGas {
                minRecommendedMaxFee = previousMaxFeePerGas
                minRecommendedTips = previousMaxPriorityFeePerGas
            }

            return Eip1559GasPriceService(evmKit: evmKit, initialMaxBaseFee: initialMaxBaseFee, initialMaxTips: initialMaxTips, minRecommendedMaxFee: minRecommendedMaxFee, minRecommendedTips: minRecommendedTips)
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
    }

    enum GasDataWarning: Warning {
        case riskOfGettingStuck
        case overpricing
    }

    struct GasPrices {
        let recommended: GasPrice
        let userDefined: GasPrice
    }

    class GasData {
        let limit: Int
        let estimatedLimit: Int
        private(set) var price: GasPrice

        init(limit: Int, estimatedLimit: Int? = nil, price: GasPrice) {
            self.limit = limit
            self.estimatedLimit = estimatedLimit ?? limit
            self.price = price
        }

        var fee: BigUInt {
            BigUInt(limit * price.max)
        }

        var estimatedFee: BigUInt {
            BigUInt(estimatedLimit * price.max)
        }

        var isSurcharged: Bool {
            limit != estimatedLimit
        }

        var description: String {
            "L1 transaction: gasLimit:\(limit) - gasPrice:\(price.description)"
        }

        func set(price: GasPrice) {
            self.price = price
        }
    }

    class RollupGasData: GasData {
        let additionalFee: BigUInt

        init(additionalFee: BigUInt, limit: Int, estimatedLimit: Int? = nil, price: GasPrice) {
            self.additionalFee = additionalFee
            super.init(limit: limit, estimatedLimit: estimatedLimit, price: price)
        }

        override var fee: BigUInt {
            super.fee + additionalFee
        }

        override var estimatedFee: BigUInt {
            super.estimatedFee + additionalFee
        }

        override var description: String {
            "L2 transaction: gasLimit:\(limit) - gasPrice:\(price.description) - l1fee:\(additionalFee.description)"
        }
    }

    struct Transaction {
        let transactionData: TransactionData
        let gasData: GasData
    }

}

protocol IEvmFeeService {
    var gasPriceService: IGasPriceService { get }
    var coinService: CoinService { get }
    var status: DataStatus<FallibleData<EvmFeeModule.Transaction>> { get }
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.Transaction>>> { get }
}

protocol IGasPriceService {
    var status: DataStatus<FallibleData<EvmFeeModule.GasPrices>> { get }
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.GasPrices>>> { get }
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
