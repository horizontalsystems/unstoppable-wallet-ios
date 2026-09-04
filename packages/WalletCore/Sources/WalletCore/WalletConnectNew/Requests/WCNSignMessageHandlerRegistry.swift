class WCNSignMessageHandlerRegistry {
    private var handlers = [IWCNSignMessageHandler]()

    func register(_ handler: IWCNSignMessageHandler) {
        handlers.append(handler)
    }

    func handler(for payload: WCNRequestPayload) -> IWCNSignMessageHandler? {
        handlers.first { $0.handles(payload) }
    }
}
