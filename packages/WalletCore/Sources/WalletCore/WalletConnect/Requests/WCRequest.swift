public struct WCRequest {
    let payload: WCRequestPayload
    let verdict: WCVerificationVerdict
    let dAppName: String
    var dAppUrl: String?
    var dAppIconUrl: String?

    var isBlocked: Bool {
        if case .block = verdict { return true }
        return false
    }
}
