import Foundation

import Foundation
import UIKit
import WalletConnectSign

class WCWalletHandler<Payload: WCWalletPayload>: WalletConnectRequestHandler {
    override var method: String { Payload.method }
    let requestFactory: Eip155RequestFactory

    init(requestFactory: Eip155RequestFactory) {
        self.requestFactory = requestFactory
    }

    private func isValidated(chainId: Int) -> Bool {
        requestFactory.evmBlockchainManager.blockchain(chainId: chainId) != nil
    }

    private func respond(request: Request, successful: Bool) throws {
        Task {
            let response: RPCResult = successful ? .response(AnyCodable("null")) : .error(.init(code: 4902, message: "Unrecognized chain ID"))
            try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: response)
        }
    }

    func name(by method: String) -> String? {
        method == Payload.method ? Payload.name : nil
    }
}

extension WCWalletHandler: IWalletConnectRequestHandler {
    func handle(session: Session, request: Request) -> WalletConnectRequestChain.RequestResult {
        guard request.method == Payload.method else {
            return .unsuccessful(error: WCRequestPayload.ParsingError.cantParseRequest)
        }

        do {
            let payload = try Payload(dAppName: session.peer.name, from: request.params)
            try respond(request: request, successful: isValidated(chainId: payload.chainId))

            return .handled
        } catch {
            return .unsuccessful(error: error)
        }
    }
}
