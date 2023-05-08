import BigInt
import EvmKit
import RxCocoa
import RxRelay
import RxSwift

class EvmRollupGasDataService: EvmCommonGasDataService {
    private let l1FeeProvider: L1FeeProvider

    init(evmKit: EvmKit.Kit, l1GasFeeContractAddress: EvmKit.Address, predefinedGasLimit: Int?) {
        l1FeeProvider = L1FeeProvider.instance(evmKit: evmKit, contractAddress: l1GasFeeContractAddress, minLogLevel: .error)

        super.init(evmKit: evmKit, predefinedGasLimit: predefinedGasLimit)
    }

    private func l1GasFeeSingle(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int) -> Single<BigUInt> {
        l1FeeProvider.getL1Fee(gasPrice: gasPrice, gasLimit: gasLimit, to: transactionData.to, value: transactionData.value, data: transactionData.input)
    }

    private func stubMaxHex(value: BigUInt) -> BigUInt {
        let hexString = String(value, radix: 16)
        let maximumHexValue = [String](repeating: "F", count: hexString.count).joined()
        let newValue = BigUInt(maximumHexValue, radix: 16) ?? (value * 10)
        return newValue
    }

    override func gasDataSingle(gasPrice: GasPrice, transactionData: TransactionData, stubAmount: BigUInt?) -> Single<EvmFeeModule.GasData> {
        if let predefinedGasLimit {
            return l1GasFeeSingle(transactionData: transactionData, gasPrice: gasPrice, gasLimit: predefinedGasLimit).map { l1GasFee in
                EvmFeeModule.RollupGasData(additionalFee: l1GasFee, limit: predefinedGasLimit, price: gasPrice)
            }
        }

        return super.gasDataSingle(gasPrice: gasPrice, transactionData: transactionData, stubAmount: stubAmount)
            .flatMap { [weak self] commonGasData in
                var l1TransactionData = transactionData
                // if we calculate stub fee for l2 layer. we need calculate l1BaseFee using maximum value converted to FFF..FFF view
                if stubAmount != nil {
                    let maxAmount = self?.stubMaxHex(value: transactionData.value) ?? transactionData.value
                    l1TransactionData = TransactionData(to: transactionData.to, value: maxAmount, input: transactionData.input)
                }

                return self?.l1GasFeeSingle(transactionData: l1TransactionData, gasPrice: gasPrice, gasLimit: commonGasData.limit)
                        .map { l1GasFee in
                            EvmFeeModule.RollupGasData(additionalFee: l1GasFee, limit: commonGasData.limit, price: gasPrice)
                        } ?? .just(EvmFeeModule.RollupGasData(additionalFee: 0, limit: commonGasData.limit, price: gasPrice))
            }
    }

}
