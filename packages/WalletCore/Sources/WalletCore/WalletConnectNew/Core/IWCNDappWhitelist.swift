enum WCNWhitelistState {
    case loading
    case loaded
    case unavailable
}

protocol IWCNDappWhitelist: AnyObject {
    var state: WCNWhitelistState { get }
    func isTrusted(host: String) -> Bool
}

protocol IWCNPremiumGate: AnyObject {
    var scamProtectionEnabled: Bool { get }
}
