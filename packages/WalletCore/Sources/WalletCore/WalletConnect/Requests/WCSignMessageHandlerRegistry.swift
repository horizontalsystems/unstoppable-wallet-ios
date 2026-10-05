class WCSignMessageHandlerRegistry {
    private var handlers = [IWCSignMessageHandler]()

    func register(_ handler: IWCSignMessageHandler) {
        handlers.append(handler)
    }

    func handler(for payload: WCRequestPayload) -> IWCSignMessageHandler? {
        handlers.first { $0.handles(payload) }
    }
}
