class WCDirectHandlerRegistry {
    private var handlers = [IWCDirectHandler]()

    func register(_ handler: IWCDirectHandler) {
        handlers.append(handler)
    }

    func handler(for payload: WCRequestPayload) -> IWCDirectHandler? {
        handlers.first { $0.handles(payload) }
    }
}
