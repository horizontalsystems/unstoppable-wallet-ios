import Combine

class WalletConnectSendViewModel: ObservableObject {
    private let request: WalletConnectRequest
    private let signService: IWalletConnectSignService = Core.shared.walletConnectSessionManager.service

    init(request: WalletConnectRequest) {
        self.request = request
    }

    var payloadTitle: String {
        switch request.payload {
        case is WCSendStellarTransactionPayload: return "wallet_connect.send.transaction".localized
        default: return request.payload.dAppName
        }
    }

    func sendButtonTitle(sending: Bool) -> String {
        switch request.payload {
        case is WCSendStellarTransactionPayload:
            return sending ? "send.confirmation.sending".localized : "button.send".localized
        default: return "wallet_connect.button.confirm".localized
        }
    }

    func reject() {
        signService.rejectRequest(id: request.id)
    }
}
