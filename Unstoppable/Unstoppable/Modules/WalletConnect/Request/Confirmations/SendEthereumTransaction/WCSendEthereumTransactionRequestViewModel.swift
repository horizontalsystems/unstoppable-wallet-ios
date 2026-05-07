import Foundation

class WCSendEthereumTransactionRequestViewModel {
    private let service: WCSendEthereumTransactionRequestService

    init(service: WCSendEthereumTransactionRequestService) {
        self.service = service
    }
}

extension WCSendEthereumTransactionRequestViewModel {
    func approve(transactionHash: Data) {
        service.approve(transactionHash: transactionHash)
    }

    func reject() {
        service.reject()
    }
}
