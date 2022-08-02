import EthereumKit
import RxCocoa
import RxRelay
import RxSwift
import MarketKit
import BigInt

protocol IEvmGasDataService {
    func gasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData>
    func stubGasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData>
    func predefinedTransaction(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData>?
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

            return EvmFeeModule.GasData.common(gasLimit: estimatedGasLimit, gasPrice: gasPrice)
        }
    }

    func stubGasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData> {
        let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: Data())
        return gasDataSingle(gasPrice: gasPrice, transactionData: stubTransactionData)
    }

    func predefinedTransaction(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData>? {
        guard let gasLimit = gasLimit else {
            return nil
        }

        return .just(EvmFeeModule.GasData.common(gasLimit: gasLimit, gasPrice: gasPrice))
    }
}

struct EvmGasDataService {
    static func instance(evmKit: EthereumKit.Kit, blockchainType: BlockchainType, gasLimitSurchargePercent: Int = 0) -> IEvmGasDataService {
        guard let rollupFeeContractAddress = blockchainType.rollupFeeContractAddress else {
            return EvmL1GasDataService(evmKit: evmKit, gasLimitSurchargePercent: gasLimitSurchargePercent)
        }

        return EvmRollupL2GasDataService(evmKit: evmKit, l1GasFeeContractAddress: rollupFeeContractAddress, gasLimitSurchargePercent: gasLimitSurchargePercent) //do not use gasLimitSurchargePercent, because l2 layers don't have mempool (can't be forced by big fee)
    }
}
