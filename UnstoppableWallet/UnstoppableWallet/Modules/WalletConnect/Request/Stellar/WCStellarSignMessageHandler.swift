import Foundation
import UIKit
import WalletConnectSign

class WCStellarSignHandler<Payload: WCStellarSignPayload>: WalletConnectRequestHandler {
    override var method: String { Payload.method }
    let requestFactory: StellarRequestFactory

    init(requestFactory: StellarRequestFactory) {
        self.requestFactory = requestFactory
    }
}

extension WCStellarSignHandler: IWalletConnectRequestHandler {
    var namespace: String { StellarProposalHandler.namespace }

    func handle(session: Session, request: Request) -> WalletConnectRequestChain.RequestResult {
        guard request.method == Payload.method else {
            return .unsuccessful(error: WCRequestPayload.ParsingError.cantParseRequest)
        }

        do {
            let payload = try Payload(dAppName: session.peer.name, from: request.params)
            let request = try requestFactory.request(request: request, payload: payload)
            return .request(request)
        } catch {
            return .unsuccessful(error: error)
        }
    }

    func name(by method: String) -> String? {
        method == Payload.method ? Payload.name : nil
    }
}

extension WCStellarSignHandler: IWalletConnectRequestViewFactory {
    func viewController(request: WalletConnectRequest) -> WalletConnectRequestChain.ViewFactoryResult {
        guard request.payload is WCSignMessagePayload else {
            return .unsuccessful(error: WalletConnectRequestChain.ViewFactoryError.cantRecognizeHandler)
        }

        let controller = Payload.module(request: request)
        return .controller(controller)
    }
}
