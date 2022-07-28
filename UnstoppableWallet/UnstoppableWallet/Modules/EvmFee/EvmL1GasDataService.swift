import EthereumKit
import RxCocoa
import RxRelay
import RxSwift
import MarketKit

protocol IEvmGasDataService {
    func gasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData>
    func transaction(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.Transaction?>
}

class EvmL1GasDataService {
    private let evmKit: EthereumKit.Kit
    private let gasLimitSurchargePercent: Int

    private var gasLimit: Int?

    init(evmKit: EthereumKit.Kit, gasLimit: Int? = nil, gasLimitSurchargePercent: Int = 0) {
        self.evmKit = evmKit
        self.gasLimit = gasLimit
        self.gasLimitSurchargePercent = gasLimitSurchargePercent
    }

    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }
}

extension EvmL1GasDataService: IEvmGasDataService {
    func gasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData> {
        evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice).map { [weak self] estimatedGasLimit in
            let gasLimit = self?.surchargedGasLimit(estimatedGasLimit: estimatedGasLimit) ?? estimatedGasLimit

            return EvmFeeModule.GasData.l1(gasLimit: estimatedGasLimit, gasPrice: gasPrice)
        }
    }

    func transaction(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.Transaction?> {
        guard let gasLimit = gasLimit else {
            return .just(nil)
        }

        return .just(EvmFeeModule.Transaction(
            transactionData: transactionData,
            gasData: EvmFeeModule.GasData.l1(gasLimit: gasLimit, gasPrice: gasPrice)
        ))
    }
}

struct EvmGasDataService {
    static func instance(evmKit: EthereumKit.Kit, blockchainType: BlockchainType, gasLimitSurchargePercent: Int = 0) -> IEvmGasDataService {
        guard let rollupFeeContractAddress = blockchainType.rollupFeeContractAddress else {
            return EvmL1GasDataService(evmKit: evmKit, gasLimitSurchargePercent: gasLimitSurchargePercent)
        }

        return EvmRollupL2GasDataService(evmKit: evmKit, l1GasFeeContractAddress: rollupFeeContractAddress) //do not use gasLimitSurchargePercent, because l2 layers don't have mempool
    }
}
