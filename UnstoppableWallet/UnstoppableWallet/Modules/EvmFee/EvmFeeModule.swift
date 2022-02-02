import UIKit
import BigInt
import EthereumKit
import RxSwift
import RxCocoa
import ThemeKit

struct EvmFeeModule {

    static func viewController(feeViewModel: EvmFeeViewModel) -> UIViewController? {
        let feeService = feeViewModel.service
        let coinService = feeViewModel.coinService
        let gasPriceService = feeService.gasPriceService

        switch gasPriceService {
        case let legacyService as LegacyGasPriceService:
            let viewModel = LegacyEvmFeeViewModel(gasPriceService: legacyService, feeService: feeService, coinService: coinService, cautionsFactory: SendEvmCautionsFactory())
            return ThemeNavigationController(rootViewController: LegacyEvmFeeViewController(viewModel: viewModel))

        default: return nil
        }
    }

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
    var gasPriceService: LegacyGasPriceService { get }
    var status: DataStatus<FallibleData<EvmFeeModule.Transaction>> { get }
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.Transaction>>> { get }
}

protocol IEvmGasPriceService {
    var customFeeRange: ClosedRange<Int> { get }
}
