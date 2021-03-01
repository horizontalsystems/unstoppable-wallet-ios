import Foundation

class WalletConnectSendEthereumTransactionRequestViewModel {
    private let service: WalletConnectSendEthereumTransactionRequestService

    init(service: WalletConnectSendEthereumTransactionRequestService) {
        self.service = service
    }

}

extension WalletConnectSendEthereumTransactionRequestViewModel {

    func approve(transactionHash: Data) {
        service.approve(transactionHash: transactionHash)
    }

    func reject() {
        service.reject()
    }

}
