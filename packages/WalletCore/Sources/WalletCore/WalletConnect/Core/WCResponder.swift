import Combine
import WalletConnectSign

class WCResponder {
    private let signClient: IWCSignClient
    private let answeredSubject = PassthroughSubject<RPCID, Never>()

    init(signClient: IWCSignClient) {
        self.signClient = signClient
    }

    // fires once the dApp has been answered, so pending-request lists can drop the request
    var answeredPublisher: AnyPublisher<RPCID, Never> {
        answeredSubject.eraseToAnyPublisher()
    }

    func respond(request: WCRequestPayload, result: AnyCodable) async throws {
        try await signClient.respond(topic: request.topic, requestId: request.id, response: .response(result))
        answeredSubject.send(request.id)
    }

    func reject(request: WCRequestPayload, reason: RejectReason) async throws {
        try await signClient.respond(topic: request.topic, requestId: request.id, response: .error(reason.rpcError))
        answeredSubject.send(request.id)
    }
}

extension WCResponder {
    enum RejectReason: Equatable {
        case userRejected
        case blocked(reason: String)
        case unsupportedMethod
        case invalidParams(reason: String)
        case unrecognizedChain

        var rpcError: JSONRPCError {
            switch self {
            case .userRejected: return JSONRPCError(code: 5000, message: "User rejected.")
            case let .blocked(reason): return JSONRPCError(code: 5000, message: "Request blocked by wallet: \(reason)")
            case .unsupportedMethod: return JSONRPCError(code: 5101, message: "Unsupported wallet method.")
            case let .invalidParams(reason): return JSONRPCError(code: -32602, message: "Invalid params: \(reason)")
            case .unrecognizedChain: return JSONRPCError(code: 4902, message: "Unrecognized chain ID")
            }
        }
    }
}
