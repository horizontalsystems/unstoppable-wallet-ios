import Combine

class TonConnectSendViewModel: ObservableObject {
    private let tonConnectManager = App.shared.tonConnectManager
    private let request: TonConnectSendTransactionRequest

    init(request: TonConnectSendTransactionRequest) {
        self.request = request
    }

    var appName: String {
        request.app.manifest.name
    }

    func reject() {
        Task { [tonConnectManager, request] in
            try await tonConnectManager.reject(request: request)
        }
    }
}
