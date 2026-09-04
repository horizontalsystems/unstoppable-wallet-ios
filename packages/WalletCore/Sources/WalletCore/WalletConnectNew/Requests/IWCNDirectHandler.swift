// Answers a request that needs neither a transaction nor a signature nor a screen
protocol IWCNDirectHandler: AnyObject {
    func handles(_ payload: WCNRequestPayload) -> Bool
    func respond(request: WCNRequest, session: WCNSessionInfo) async throws
}
