// Bridges SendHandlerFactory (type-based) to the per-chain registry assembled by the facade
class WCSendHandlerProvider: SendHandler {
    static var registry: WCSendHandlerRegistry?

    override class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .walletConnect(inner, request) = sendData else { return nil }
        return registry?.handler(request: request, inner: inner)
    }
}
