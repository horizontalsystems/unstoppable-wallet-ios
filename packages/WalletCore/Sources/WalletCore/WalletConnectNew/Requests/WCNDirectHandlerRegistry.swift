class WCNDirectHandlerRegistry {
    private var handlers = [IWCNDirectHandler]()

    func register(_ handler: IWCNDirectHandler) {
        handlers.append(handler)
    }

    func handler(for payload: WCNRequestPayload) -> IWCNDirectHandler? {
        handlers.first { $0.handles(payload) }
    }
}
