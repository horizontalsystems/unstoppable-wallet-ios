class WCNSendHandlerRegistry {
    private var factories = [IWCNSendHandlerFactory]()

    func register(_ factory: IWCNSendHandlerFactory) {
        factories.append(factory)
    }

    func handler(request: WCNRequest, inner: SendData) -> ISendHandler? {
        for factory in factories {
            if let handler = factory.handler(request: request, inner: inner) {
                return handler
            }
        }
        return nil
    }
}
