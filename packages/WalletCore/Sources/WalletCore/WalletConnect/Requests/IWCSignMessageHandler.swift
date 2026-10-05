// Signs a message payload and answers the dApp; the confirmation screen lives in UI
protocol IWCSignMessageHandler: AnyObject {
    func handles(_ payload: WCRequestPayload) -> Bool
    func sign(request: WCRequest) async throws
}
