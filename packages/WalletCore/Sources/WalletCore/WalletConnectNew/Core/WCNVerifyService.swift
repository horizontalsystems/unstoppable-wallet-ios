import Foundation
import ReownWalletKit

// Bug-bounty #3: the badge is derived from the SDK-attested origin, never from dApp metadata
class WCNVerifyService {
    private let whitelist: IWCNDappWhitelist?
    private let premiumGate: IWCNPremiumGate?

    init(whitelist: IWCNDappWhitelist? = nil, premiumGate: IWCNPremiumGate? = nil) {
        self.whitelist = whitelist
        self.premiumGate = premiumGate
    }

    func state(context: VerifyContext?) -> WCNVerifyState {
        switch context?.validation {
        case .scam: return .scam
        case .invalid: return .invalid
        case .unknown, nil: return .unknown
        case .valid:
            guard let origin = context?.origin else { return .unknown }
            return isTrusted(origin: origin) ? .trusted(origin: origin) : .verified(origin: origin)
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
enum WCNWhitelistMatcher {
    static func matches(host: String, allowed: String) -> Bool {
        let allowed = allowed.lowercased()
        return host == allowed || host.hasSuffix("." + allowed)
    }
}
