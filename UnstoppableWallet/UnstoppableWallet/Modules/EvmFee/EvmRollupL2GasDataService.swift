import BigInt
import EthereumKit
import RxCocoa
import RxRelay
import RxSwift

class EvmRollupL2GasDataService {
    private let evmKit: EthereumKit.Kit
    private let l1GasFeeContractAddress: EthereumKit.Address
    private let gasLimitSurchargePercent: Int
    private let l1FeeProvider: L1FeeProvider

    private var gasLimit: Int?

    init(evmKit: EthereumKit.Kit, l1GasFeeContractAddress: EthereumKit.Address, gasLimit: Int? = nil, gasLimitSurchargePercent: Int = 0) {
        self.evmKit = evmKit
        self.l1GasFeeContractAddress = l1GasFeeContractAddress
        self.gasLimit = gasLimit
        self.gasLimitSurchargePercent = gasLimitSurchargePercent

        l1FeeProvider = L1FeeProvider.instance(evmKit: evmKit, contractAddress: l1GasFeeContractAddress, minLogLevel: .error)
    }

    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }

    private func l1GasFeeSingle(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int) -> Single<BigUInt> {
        l1FeeProvider.getL1Fee(gasPrice: gasPrice, gasLimit: gasLimit, to: transactionData.to, value: transactionData.value, data: transactionData.input, nonce: transactionData.nonce ?? 1)
    }
}

extension EvmRollupL2GasDataService: IEvmGasDataService {
    func gasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData> {
        evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice).flatMap { [weak self] estimatedGasLimit in
            let gasLimit = self?.surchargedGasLimit(estimatedGasLimit: estimatedGasLimit) ?? estimatedGasLimit

            return self?.l1GasFeeSingle(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit).map { l1GasFee in
                EvmFeeModule.GasData.rollupL2(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: l1GasFee)
            } ?? .just(EvmFeeModule.GasData.rollupL2(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: 0))
        }
    }

    func transaction(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.Transaction?> {
        guard let gasLimit = gasLimit else {
            return .just(nil)
        }

        return l1GasFeeSingle(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit).map { l1GasFee in
            EvmFeeModule.Transaction(
                transactionData: transactionData,
                gasData: EvmFeeModule.GasData.rollupL2(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: l1GasFee)
            )
        }
    }
}
