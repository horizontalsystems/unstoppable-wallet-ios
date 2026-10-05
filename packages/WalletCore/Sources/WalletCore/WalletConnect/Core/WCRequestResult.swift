enum WCRequestResult {
    case transaction(request: WCRequest, sendData: SendData)
    case signMessage(request: WCRequest)
    case direct(request: WCRequest)
    // the dApp has already been answered with an error
    case rejected(reason: WCResponder.RejectReason)
}
