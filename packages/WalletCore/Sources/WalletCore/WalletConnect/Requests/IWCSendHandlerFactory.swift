protocol IWCSendHandlerFactory: AnyObject {
    func handler(request: WCRequest, inner: SendData?) -> ISendHandler?
}
