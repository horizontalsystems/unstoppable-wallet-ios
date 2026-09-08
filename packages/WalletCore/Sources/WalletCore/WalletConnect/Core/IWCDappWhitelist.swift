enum WCWhitelistState {
    case loading
    case loaded
    case unavailable
}

protocol IWCDappWhitelist: AnyObject {
    var state: WCWhitelistState { get }
    func isTrusted(host: String) -> Bool
}

protocol IWCPremiumGate: AnyObject {
    var scamProtectionEnabled: Bool { get }
}
