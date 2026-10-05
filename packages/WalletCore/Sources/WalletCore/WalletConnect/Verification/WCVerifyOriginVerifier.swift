import ReownWalletKit

// Bug-bounty #3: attested origin from the SDK Verify API, never dApp-supplied metadata
class WCVerifyOriginVerifier: IWCVerifier {
    func handles(_: WCVerificationContext) -> Bool {
        true
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        switch context.verifyContext?.validation {
        case .scam: return .block(reason: .originScam)
        case .invalid: return .caution(reason: .originInvalid)
        case .valid, .unknown, nil: return .pass
        }
    }
}
