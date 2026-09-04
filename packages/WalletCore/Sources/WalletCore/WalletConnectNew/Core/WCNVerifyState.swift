enum WCNVerifyState: Equatable {
    case scam
    case invalid
    case unknown
    case verified(origin: String)
    // premium whitelist hit on the attested origin
    case trusted(origin: String)
}
