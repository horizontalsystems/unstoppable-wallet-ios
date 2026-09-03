enum WCNRequestResult {
    case transaction(request: WCNRequest, sendData: SendData)
    case signMessage(request: WCNRequest)
    case direct(request: WCNRequest)
    // the dApp has already been answered with an error
    case rejected(reason: WCNResponder.RejectReason)
}
