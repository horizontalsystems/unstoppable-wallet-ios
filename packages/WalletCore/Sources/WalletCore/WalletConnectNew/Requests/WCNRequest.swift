public struct WCNRequest {
    let parsed: WCNParsedRequest
    let verdict: WCNVerificationVerdict
    let dAppName: String

    var isBlocked: Bool {
        if case .block = verdict { return true }
        return false
    }
}
