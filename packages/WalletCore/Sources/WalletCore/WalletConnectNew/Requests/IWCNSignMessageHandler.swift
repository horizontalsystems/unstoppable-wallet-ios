// Signs a message payload and answers the dApp; the confirmation screen lives in UI
protocol IWCNSignMessageHandler: AnyObject {
    func handles(_ payload: WCNRequestPayload) -> Bool
    func sign(request: WCNRequest) async throws
}
