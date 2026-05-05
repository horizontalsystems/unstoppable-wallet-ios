enum SignatureCurve: String {
    case secp256r1
    case secp256k1

    /// SmartAccountProfile.implementationVersion tag for this curve.
    var implementationVersion: String {
        switch self {
        case .secp256r1: return "barz_v1_0_0"
        case .secp256k1: return "barz_v1_ecdsa"
        }
    }
}
