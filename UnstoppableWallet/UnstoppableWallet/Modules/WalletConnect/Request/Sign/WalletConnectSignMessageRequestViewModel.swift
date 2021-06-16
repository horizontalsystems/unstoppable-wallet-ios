class WalletConnectSignMessageRequestViewModel {
    private let service: WalletConnectSignMessageRequestService


    init(service: WalletConnectSignMessageRequestService) {
        self.service = service
    }

}

extension WalletConnectSignMessageRequestViewModel {

    var message: String {
        service.message
    }

    var domain: String? {
        service.domain
    }

    func sign() throws {
        try service.sign()
    }

    func reject() {
        service.reject()
    }

}
