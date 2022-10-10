import Foundation
import EvmKit

class WalletConnectSendEthereumTransactionRequestService {
    private let request: WalletConnectSendEthereumTransactionRequest
    private let signService: IWalletConnectSignService

    init(request: WalletConnectSendEthereumTransactionRequest, baseService: IWalletConnectSignService) {
        self.request = request
        signService = baseService
    }

}

extension WalletConnectSendEthereumTransactionRequestService {

    var transactionData: TransactionData {
        TransactionData(
                to: request.transaction.to,
                value: request.transaction.value,
                input: request.transaction.data
        )
    }

    var gasPrice: GasPrice? {
        if let maxFeePerGas = request.transaction.maxFeePerGas,
           let maxPriorityFeePerGas = request.transaction.maxPriorityFeePerGas {
            return GasPrice.eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
        }

        return request.transaction.gasPrice.flatMap { GasPrice.legacy(gasPrice: $0) }
    }

    func approve(transactionHash: Data) {
        signService.approveRequest(id: request.id, result: transactionHash)
    }

    func reject() {
        signService.rejectRequest(id: request.id)
    }

}
