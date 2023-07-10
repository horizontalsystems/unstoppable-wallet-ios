import Foundation
import WalletConnectSign

class SessionRequestFilterManager {
    private let rejectList = [
        // 1Inch custom methods
        "personal_ecRecover",
        "eth_getCode",
        "wallet_switchEthereumChain",
        "wallet_addEthereumChain"
    ]

    private func reject(request: Request) {
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.init(code: 5000, message: "Reject by User")))
            } catch {
                print(error)
            }
        }

    }

    func handle(request: Request) -> Bool {
        if rejectList.contains(request.method) {
            reject(request: request)
            return true
        }
        return false
    }

}
