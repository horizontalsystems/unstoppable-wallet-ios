import BigInt
import EvmKit
import MarketKit

struct EvmFeeEstimator {
    private static let surchargePercent: Double = 10

    private func _estimateFee(evmKitWrapper: EvmKitWrapper, transactionData: TransactionData, gasPrice: GasPrice, predefinedGasLimit: Int? = nil) async throws -> EvmFeeData {
        let evmKit = evmKitWrapper.evmKit
        let gasLimit: Int

        if let predefinedGasLimit {
            gasLimit = predefinedGasLimit
        } else {
            gasLimit = try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
        }

        let txAmount = transactionData.value
        let feeAmount = BigUInt(gasLimit * gasPrice.max)
        var totalAmount = txAmount + feeAmount

        var l1Fee: BigUInt?

        if let contractAddress = evmKitWrapper.blockchainType.rollupFeeContractAddress {
            let l1FeeProvider = L1FeeProvider.instance(evmKit: evmKit, contractAddress: contractAddress)
            let _l1Fee = try await l1FeeProvider.l1Fee(gasPrice: gasPrice, gasLimit: gasLimit, to: transactionData.to, value: transactionData.value, data: transactionData.input)
            l1Fee = _l1Fee
            totalAmount += _l1Fee
        }

        let evmBalance = evmKit.accountState?.balance ?? 0

        let surchargedGasLimit: Int

        if !transactionData.input.isEmpty, evmBalance > totalAmount {
            let remainingBalance = evmBalance - totalAmount

            var additionalGasLimit = Int(Double(gasLimit) / 100.0 * Self.surchargePercent)

            if remainingBalance < BigUInt(additionalGasLimit * gasPrice.max) {
                additionalGasLimit = Int((remainingBalance / BigUInt(gasPrice.max)).description) ?? 0
            }

            surchargedGasLimit = gasLimit + additionalGasLimit
        } else {
            surchargedGasLimit = gasLimit
        }

        return .init(gasLimit: gasLimit, surchargedGasLimit: surchargedGasLimit, l1Fee: l1Fee)
    }

    func estimateFee(evmKitWrapper: EvmKitWrapper, transactionData: TransactionData, gasPriceData: GasPriceData, predefinedGasLimit _: Int? = nil) async throws -> EvmFeeData {
        do {
            return try await _estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPrice: gasPriceData.userDefined)
        } catch {
            if case let AppError.ethereum(reason: ethereumError) = error.convertedError, case .lowerThanBaseGasLimit = ethereumError {
                return try await _estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPrice: gasPriceData.recommended)
            } else {
                throw error
            }
        }
    }
}
