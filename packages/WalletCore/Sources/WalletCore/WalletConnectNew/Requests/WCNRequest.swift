public struct WCNRequest {
    let payload: WCNRequestPayload
    let verdict: WCNVerificationVerdict
    let dAppName: String
    var dAppUrl: String?
    var dAppIconUrl: String?

    var isBlocked: Bool {
        if case .block = verdict { return true }
        return false
    }
}
