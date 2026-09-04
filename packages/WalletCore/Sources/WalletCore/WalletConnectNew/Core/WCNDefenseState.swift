// What the Defense System block shows; security decisions stay in WCNVerifyState
enum WCNDefenseState: Equatable {
    case disabled
    case loading
    case notAvailable
    case safe
    case danger
    case scam
}
