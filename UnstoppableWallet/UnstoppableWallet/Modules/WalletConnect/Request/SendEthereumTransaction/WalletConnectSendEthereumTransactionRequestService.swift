import EthereumKit

class WalletConnectSendEthereumTransactionRequestService {
    private let request: WalletConnectSendEthereumTransactionRequest
    private let signService: IWalletConnectSignService

    init(request: WalletConnectSendEthereumTransactionRequest, baseService: IWalletConnectSignService) {
        self.request = request
        self.signService = baseService
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
        signService.approveRequest(id: request.id, result: transactionHash)
    }

    func reject() {
        signService.rejectRequest(id: request.id)
    }

}
