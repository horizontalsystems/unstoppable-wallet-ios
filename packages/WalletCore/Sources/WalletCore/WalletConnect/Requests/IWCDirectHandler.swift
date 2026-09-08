// Answers a request that needs neither a transaction nor a signature nor a screen
protocol IWCDirectHandler: AnyObject {
    func handles(_ payload: WCRequestPayload) -> Bool
    func respond(request: WCRequest, session: WCSessionInfo) async throws
}
