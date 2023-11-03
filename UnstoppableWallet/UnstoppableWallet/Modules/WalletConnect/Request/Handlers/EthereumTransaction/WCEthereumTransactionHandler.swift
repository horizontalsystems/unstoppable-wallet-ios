import Foundation
import UIKit
import WalletConnectSign

class WCEthereumTransactionHandler<Payload: WCEthereumTransactionPayload>: WalletConnectRequestHandler {
    override var method: String { Payload.method }
    let requestFactory: Eip155RequestFactory

    init(requestFactory: Eip155RequestFactory) {
        self.requestFactory = requestFactory
    }
}

extension WCEthereumTransactionHandler: IWalletConnectRequestHandler {
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
}

extension WCEthereumTransactionHandler: IWalletConnectRequestViewFactory {
    func viewController(request: WalletConnectRequest) -> WalletConnectRequestChain.ViewFactoryResult {
        guard request.payload is WCEthereumTransactionPayload else {
            return .unsuccessful(error: WalletConnectRequestChain.ViewFactoryError.cantRecognizeHandler)
        }

        let controller = Payload.module(request: request)
        return .controller(controller)
    }
}
