import Foundation
import ReownWalletKit

// Bug-bounty #3: the badge is derived from the SDK-attested origin, never from dApp metadata
class WCVerifyService {
    private let whitelist: IWCDappWhitelist?
    private let premiumGate: IWCPremiumGate?

    init(whitelist: IWCDappWhitelist? = nil, premiumGate: IWCPremiumGate? = nil) {
        self.whitelist = whitelist
        self.premiumGate = premiumGate
    }

    func state(context: VerifyContext?) -> WCVerifyState {
        switch context?.validation {
        case .scam: return .scam
        case .invalid: return .invalid
        case .unknown, nil: return .unknown
        case .valid:
            guard let origin = context?.origin else { return .unknown }
            return isTrusted(origin: origin) ? .trusted(origin: origin) : .verified(origin: origin)
        }
    }

    func defenseState(context: VerifyContext?) -> WCDefenseState {
        let verifyState = state(context: context)
        if case .scam = verifyState {
            return .scam
        }
        if case .trusted = verifyState {
            return whitelistDefenseState(trusted: true)
        }
        return whitelistDefenseState(trusted: false)
    }

    // an approved session has no attestation any more: the check runs against the peer url, as Android does
    func defenseState(peerUrl: String) -> WCDefenseState {
        whitelistDefenseState(trusted: isTrusted(origin: peerUrl))
    }

    private func whitelistDefenseState(trusted: Bool) -> WCDefenseState {
        guard premiumGate?.scamProtectionEnabled == true, let whitelist else {
            return .disabled
        }
        switch whitelist.state {
        case .loading: return .loading
        case .unavailable: return .notAvailable
        case .loaded: return trusted ? .safe : .danger
        }
    }

    private func isTrusted(origin: String) -> Bool {
        guard premiumGate?.scamProtectionEnabled == true, let whitelist,
              let host = URLComponents(string: origin)?.host?.lowercased(),
              host.allSatisfy(\.isASCII)
        else {
            return false
        }
        return whitelist.isTrusted(host: host)
    }
}

// exact host or a subdomain of an whitelisted domain; suffix tricks like evil-uniswap.org do not match
enum WCWhitelistMatcher {
    static func matches(host: String, allowed: String) -> Bool {
        let allowed = allowed.lowercased()
        return host == allowed || host.hasSuffix("." + allowed)
    }
}
