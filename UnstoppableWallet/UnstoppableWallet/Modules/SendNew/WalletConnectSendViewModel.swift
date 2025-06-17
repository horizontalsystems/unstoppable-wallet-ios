import Combine

class WalletConnectSendViewModel: ObservableObject {
    private let request: WalletConnectRequest
    private let signService: IWalletConnectSignService = Core.shared.walletConnectSessionManager.service

    init(request: WalletConnectRequest) {
        self.request = request
    }

    var dAppName: String {
        request.payload.dAppName
    }

    func reject() {
        signService.rejectRequest(id: request.id)
    }
}
