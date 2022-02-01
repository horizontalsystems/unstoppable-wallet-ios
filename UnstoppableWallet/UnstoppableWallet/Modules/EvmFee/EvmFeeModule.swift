import BigInt
import EthereumKit
import RxSwift

struct EvmFeeModule {



}

extension EvmFeeModule {

    enum GasPrice {
        case legacy(gasPrice: Int)
        case eip1559(maxPrice: Int, maxPriorityPrice: Int)

        var max: Int {
            switch self {
            case .legacy(let gasPrice): return gasPrice
            case .eip1559(let maxPrice, _): return maxPrice
            }
        }
    }

    enum GasDataError: Error {
        case insufficientBalance
    }

    enum GasDataWarning: Warning {
        case riskOfGettingStuck
        case highBaseFee
        case overpricing
    }

    struct GasData {
        let gasLimit: Int
        let gasPrice: GasPrice

        var fee: BigUInt {
            BigUInt(gasLimit * gasPrice.max)
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

protocol IEvmGasPriceService {
    var customFeeRange: ClosedRange<Int> { get }
}
