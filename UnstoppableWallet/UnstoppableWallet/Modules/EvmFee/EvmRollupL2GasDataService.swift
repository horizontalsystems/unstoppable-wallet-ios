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

    init(evmKit: EthereumKit.Kit, l1GasFeeContractAddress: EthereumKit.Address, gasLimit: Int? = nil, gasLimitSurchargePercent _: Int = 0) {
        self.evmKit = evmKit
        self.l1GasFeeContractAddress = l1GasFeeContractAddress
        self.gasLimit = gasLimit
        gasLimitSurchargePercent = 20

        l1FeeProvider = L1FeeProvider.instance(evmKit: evmKit, contractAddress: l1GasFeeContractAddress, minLogLevel: .error)
    }

    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }

    private func surchargedL1Fee(fee: BigUInt) -> BigUInt {
        fee + BigUInt(fee / 100 * BigUInt(gasLimitSurchargePercent))
    }

    private func l1GasFeeSingle(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int) -> Single<BigUInt> {
        l1FeeProvider.getL1Fee(gasPrice: gasPrice, gasLimit: gasLimit, to: transactionData.to, value: transactionData.value, data: transactionData.input, nonce: transactionData.nonce ?? 1)
    }

    private func stubMaxHex(value: BigUInt) -> BigUInt {
        let hexString = String(value, radix: 16)
        let maximumHexValue = [String](repeating: "F", count: hexString.count).joined()
        let newValue = BigUInt(maximumHexValue, radix: 16) ?? (value * 10)
        return newValue
    }
}

extension EvmRollupL2GasDataService: IEvmGasDataService {
    func gasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData> {
        evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice).flatMap { [weak self] estimatedGasLimit in
            let gasLimit = self?.surchargedGasLimit(estimatedGasLimit: estimatedGasLimit) ?? estimatedGasLimit

            return self?.l1GasFeeSingle(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit).map { l1GasFee in
                EvmFeeModule.GasData.rollup(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: l1GasFee)
            } ?? .just(EvmFeeModule.GasData.rollup(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: 0))
        }
    }

    func stubGasDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData> {
        let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: Data())
        return evmKit.estimateGas(transactionData: stubTransactionData, gasPrice: gasPrice).flatMap { [weak self] estimatedGasLimit in
            let gasLimit = self?.surchargedGasLimit(estimatedGasLimit: estimatedGasLimit) ?? estimatedGasLimit

            let maximumTransactionData = TransactionData(to: transactionData.to, value: self?.stubMaxHex(value: transactionData.value) ?? transactionData.value, input: Data())
            return self?.l1GasFeeSingle(transactionData: maximumTransactionData, gasPrice: gasPrice, gasLimit: gasLimit).map { l1GasFee in
                EvmFeeModule.GasData.rollup(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: l1GasFee)
            } ?? .just(EvmFeeModule.GasData.rollup(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: 0))
        }
    }

    func predefinedTransaction(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.GasData>? {
        guard let gasLimit = gasLimit else {
            return nil
        }

        return l1GasFeeSingle(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit).map { l1GasFee in
            EvmFeeModule.GasData.rollup(gasLimit: gasLimit, gasPrice: gasPrice, l1Fee: l1GasFee)
        }
    }
}
