import EvmKit
import Foundation

class WCSendEthereumTransactionRequestService {
    private let request: WalletConnectRequest
    private let payload: WCSendEthereumTransactionPayload
    private let signService: IWalletConnectSignService

    init?(request: WalletConnectRequest, baseService: IWalletConnectSignService) {
        guard let payload = request.payload as? WCSendEthereumTransactionPayload else {
            return nil
        }
        self.payload = payload
        self.request = request
        signService = baseService
    }
}

extension WCSendEthereumTransactionRequestService {
    var transactionData: TransactionData {
        TransactionData(
            to: payload.transaction.to,
            value: payload.transaction.value,
            input: payload.transaction.data
        )
    }

    var gasPrice: GasPrice? {
        if let maxFeePerGas = payload.transaction.maxFeePerGas,
           let maxPriorityFeePerGas = payload.transaction.maxPriorityFeePerGas
        {
            return GasPrice.eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
        }

        return payload.transaction.gasPrice.flatMap { GasPrice.legacy(gasPrice: $0) }
    }

    func approve(transactionHash: Data) {
        signService.approveRequest(id: request.id, result: transactionHash)
    }

    func reject() {
        signService.rejectRequest(id: request.id)
    }
}
