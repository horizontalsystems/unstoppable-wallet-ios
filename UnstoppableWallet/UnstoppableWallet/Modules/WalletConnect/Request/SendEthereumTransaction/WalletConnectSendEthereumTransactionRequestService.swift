import EthereumKit

class WalletConnectSendEthereumTransactionRequestService {
    private let request: WalletConnectSendEthereumTransactionRequest
    private let baseService: WalletConnectV1XMainService

    init(request: WalletConnectSendEthereumTransactionRequest, baseService: WalletConnectV1XMainService) {
        self.request = request
        self.baseService = baseService
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

    var gasPrice: Int? {
        request.transaction.gasPrice
    }

    func approve(transactionHash: Data) {
        baseService.approveRequest(id: request.id, result: transactionHash)
    }

    func reject() {
        baseService.rejectRequest(id: request.id)
    }

}
