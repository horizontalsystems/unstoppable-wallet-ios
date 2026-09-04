protocol IWCNDappWhitelist: AnyObject {
    func isTrusted(host: String) -> Bool
}

protocol IWCNPremiumGate: AnyObject {
    var scamProtectionEnabled: Bool { get }
}
