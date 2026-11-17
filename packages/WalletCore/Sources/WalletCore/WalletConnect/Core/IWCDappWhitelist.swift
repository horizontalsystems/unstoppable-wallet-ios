import Combine

enum WCWhitelistState {
    case loading
    case loaded
    case unavailable
}

protocol IWCDappWhitelist: AnyObject {
    var state: WCWhitelistState { get }
    /// fires after `state` has changed, on whatever thread the load finished on
    var statePublisher: AnyPublisher<WCWhitelistState, Never> { get }
    func isTrusted(host: String) -> Bool
}

protocol IWCScamProtectionGate: AnyObject {
    var scamProtectionEnabled: Bool { get }
}
