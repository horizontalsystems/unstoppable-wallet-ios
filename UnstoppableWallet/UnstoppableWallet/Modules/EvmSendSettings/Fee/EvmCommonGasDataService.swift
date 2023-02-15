import BigInt
import EvmKit
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class EvmCommonGasDataService {
    private let evmKit: EvmKit.Kit
    private let gasLimitSurchargePercent: Int

    private(set) var gasLimit: Int?

    init(evmKit: EvmKit.Kit, gasLimit: Int? = nil, gasLimitSurchargePercent: Int = 0) {
        self.evmKit = evmKit
        self.gasLimit = gasLimit
        self.gasLimitSurchargePercent = gasLimitSurchargePercent
    }

    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }

    func gasDataSingle(gasPrice: GasPrice, transactionData: TransactionData, stubAmount: BigUInt? = nil) -> Single<EvmFeeModule.GasData> {
        let adjustedTransactionData = stubAmount.map { TransactionData(to: transactionData.to, value: $0, input: transactionData.input) } ?? transactionData

        return evmKit.estimateGas(transactionData: adjustedTransactionData, gasPrice: gasPrice).map { [weak self] estimatedGasLimit in
            let gasLimit = self?.surchargedGasLimit(estimatedGasLimit: estimatedGasLimit) ?? estimatedGasLimit

            return EvmFeeModule.GasData(limit: gasLimit, price: gasPrice)
        }
    }

    func predefinedGasData(gasPrice: GasPrice, transactionData _: TransactionData) -> Single<EvmFeeModule.GasData>? {
        guard let gasLimit = gasLimit else {
            return nil
        }

        return .just(EvmFeeModule.GasData(limit: gasLimit, price: gasPrice))
    }
}

extension EvmCommonGasDataService {
    static func instance(evmKit: EvmKit.Kit, blockchainType: BlockchainType, gasLimit: Int? = nil, gasLimitSurchargePercent: Int = 0) -> EvmCommonGasDataService {
        guard let rollupFeeContractAddress = blockchainType.rollupFeeContractAddress else {
            return EvmCommonGasDataService(evmKit: evmKit, gasLimit: gasLimit, gasLimitSurchargePercent: gasLimitSurchargePercent)
        }

        return EvmRollupGasDataService(evmKit: evmKit, l1GasFeeContractAddress: rollupFeeContractAddress, gasLimitSurchargePercent: gasLimitSurchargePercent)
    }
}
