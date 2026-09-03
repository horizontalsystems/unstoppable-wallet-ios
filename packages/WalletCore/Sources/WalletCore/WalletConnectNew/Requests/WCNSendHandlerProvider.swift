// Bridges SendHandlerFactory (type-based) to the per-chain registry assembled by the facade
class WCNSendHandlerProvider: SendHandler {
    static var registry: WCNSendHandlerRegistry?

    override class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .walletConnectNew(inner, request) = sendData else { return nil }
        return registry?.handler(request: request, inner: inner)
    }
}
