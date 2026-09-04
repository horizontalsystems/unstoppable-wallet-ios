import WalletConnectSign

class WCNEvmWalletChainHandler: IWCNDirectHandler {
    private let chainResolver: IWCNEvmChainResolver
    private let responder: WCNResponder

    init(chainResolver: IWCNEvmChainResolver, responder: WCNResponder) {
        self.chainResolver = chainResolver
        self.responder = responder
    }

    func handles(_ payload: WCNRequestPayload) -> Bool {
        payload is WCNEvmWalletChainPayload
    }

    func respond(request: WCNRequest, session: WCNSessionInfo) async throws {
        guard let payload = request.payload as? WCNEvmWalletChainPayload else {
            return
        }

        if case let .block(reason) = request.verdict {
            try await responder.reject(request: payload, reason: .blocked(reason: String(describing: reason)))
            return
        }

        let approved = session.approvedAccounts.contains { $0.namespace == WCNNamespace.eip155 && $0.reference == String(payload.targetChainId) }
        guard approved, chainResolver.isKnown(chainId: payload.targetChainId) else {
            try await responder.reject(request: payload, reason: .unrecognizedChain)
            return
        }

        // reown AnyCodable cannot encode a bare JSON null, so the wallet answers the string "null" as the old module did
        try await responder.respond(request: payload, result: AnyCodable("null"))
    }
}
