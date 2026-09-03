protocol IWCNSendHandlerFactory: AnyObject {
    func handler(request: WCNRequest, inner: SendData?) -> ISendHandler?
}
