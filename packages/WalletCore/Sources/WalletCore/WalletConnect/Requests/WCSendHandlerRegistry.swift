class WCSendHandlerRegistry {
    private var factories = [IWCSendHandlerFactory]()

    func register(_ factory: IWCSendHandlerFactory) {
        factories.append(factory)
    }

    func handler(request: WCRequest, inner: SendData?) -> ISendHandler? {
        for factory in factories {
            if let handler = factory.handler(request: request, inner: inner) {
                return handler
            }
        }
        return nil
    }
}
