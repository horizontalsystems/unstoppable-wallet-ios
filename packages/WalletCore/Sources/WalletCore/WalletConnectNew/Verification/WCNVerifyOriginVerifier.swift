import ReownWalletKit

// Bug-bounty #3: attested origin from the SDK Verify API, never dApp-supplied metadata
class WCNVerifyOriginVerifier: IWCNVerifier {
    func handles(_: WCNVerificationContext) -> Bool {
        true
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        switch context.verifyContext?.validation {
        case .scam: return .block(reason: "Origin is flagged as scam")
        case .invalid: return .caution(reason: "Origin does not match the verified domain")
        case .valid, .unknown, nil: return .pass
        }
    }
}
