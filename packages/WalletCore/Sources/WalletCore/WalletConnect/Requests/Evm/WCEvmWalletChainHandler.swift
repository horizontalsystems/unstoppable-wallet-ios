import WalletConnectSign

class WCEvmWalletChainHandler: IWCDirectHandler {
    private let chainResolver: IWCEvmChainResolver
    private let responder: WCResponder

    init(chainResolver: IWCEvmChainResolver, responder: WCResponder) {
        self.chainResolver = chainResolver
        self.responder = responder
    }

    func handles(_ payload: WCRequestPayload) -> Bool {
        payload is WCEvmWalletChainPayload
    }

    func respond(request: WCRequest, session: WCSessionInfo) async throws {
        guard let payload = request.payload as? WCEvmWalletChainPayload else {
            return
        }

        if case let .block(reason) = request.verdict {
            try await responder.reject(request: payload, reason: .blocked(reason: String(describing: reason)))
            return
        }

        let approved = session.approvedAccounts.contains { $0.namespace == WCNamespace.eip155 && $0.reference == String(payload.targetChainId) }
        guard approved, chainResolver.isKnown(chainId: payload.targetChainId) else {
            try await responder.reject(request: payload, reason: .unrecognizedChain)
            return
        }

        // reown AnyCodable cannot encode a bare JSON null, so the wallet answers the string "null" as the old module did
        try await responder.respond(request: payload, result: AnyCodable("null"))
    }
}
