import BigInt
import EvmKit
import MarketKit
import OneInchKit

struct EvmFeeEstimator {
    func estimateFee(blockchainType: BlockchainType, evmKit: EvmKit.Kit, transactionData: TransactionData, gasPrice: GasPrice) async throws -> EvmFeeData {
        let gasLimit = try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)

        var l1Fee: BigUInt?

        if let contractAddress = blockchainType.rollupFeeContractAddress {
            let l1FeeProvider = L1FeeProvider.instance(evmKit: evmKit, contractAddress: contractAddress)
            l1Fee = try await l1FeeProvider.l1Fee(gasPrice: gasPrice, gasLimit: gasLimit, to: transactionData.to, value: transactionData.value, data: transactionData.input)
        }

        return .init(gasLimit: gasLimit, l1Fee: l1Fee)
    }

    func oneIncheEstimateFee(blockchainType: BlockchainType, evmKit: EvmKit.Kit, swap: Swap, gasPrice: GasPrice) async throws -> EvmFeeData {
        let transaction = swap.transaction
        let gasLimit = swap.transaction.gasLimit

        var l1Fee: BigUInt?

        if let contractAddress = blockchainType.rollupFeeContractAddress {
            let l1FeeProvider = L1FeeProvider.instance(evmKit: evmKit, contractAddress: contractAddress)
            l1Fee = try await l1FeeProvider.l1Fee(gasPrice: gasPrice, gasLimit: gasLimit, to: transaction.to, value: transaction.value, data: transaction.data)
        }

        return .init(gasLimit: gasLimit, l1Fee: l1Fee)
    }
}
