import ReownWalletKit
import Testing
@testable import WalletCore

struct WCVerifyServiceTests {
    private let origin = "https://app.uniswap.org"

    private func context(_ validation: VerifyContext.ValidationStatus, origin: String? = "https://app.uniswap.org") -> VerifyContext {
        VerifyContext(origin: origin, validation: validation)
    }

    @Test func baseStatesFollowSdkValidation() {
        let service = WCVerifyService()
        #expect(service.state(context: context(.scam)) == .scam)
        #expect(service.state(context: context(.invalid)) == .invalid)
        #expect(service.state(context: context(.unknown)) == .unknown)
        #expect(service.state(context: nil) == .unknown)
        #expect(service.state(context: context(.valid)) == .verified(origin: origin))
        #expect(service.state(context: context(.valid, origin: nil)) == .unknown)
    }

    @Test func premiumWhitelistTrustsAttestedOrigin() {
        let service = WCVerifyService(whitelist: StubWhitelist(domains: ["uniswap.org"]), premiumGate: StubGate(enabled: true))
        #expect(service.state(context: context(.valid)) == .trusted(origin: origin))
        #expect(service.state(context: context(.valid, origin: "https://uniswap.org")) == .trusted(origin: "https://uniswap.org"))
    }

    @Test func whitelistNeverUpgradesUnverifiedOrigin() {
        let service = WCVerifyService(whitelist: StubWhitelist(domains: ["uniswap.org"]), premiumGate: StubGate(enabled: true))
        #expect(service.state(context: context(.unknown)) == .unknown)
        #expect(service.state(context: context(.invalid)) == .invalid)
        #expect(service.state(context: context(.scam)) == .scam)
    }

    @Test func suffixSpoofAndPunycodeAreNotTrusted() {
        let service = WCVerifyService(whitelist: StubWhitelist(domains: ["uniswap.org"]), premiumGate: StubGate(enabled: true))
        #expect(service.state(context: context(.valid, origin: "https://evil-uniswap.org")) == .verified(origin: "https://evil-uniswap.org"))
        #expect(service.state(context: context(.valid, origin: "https://uniswap.org.evil.com")) == .verified(origin: "https://uniswap.org.evil.com"))
        #expect(service.state(context: context(.valid, origin: "https://uniswаp.org")) == .verified(origin: "https://uniswаp.org"))
    }

    @Test func defenseStateFollowsPremiumWhitelistAndScam() {
        let whitelist = StubWhitelist(domains: ["uniswap.org"])
        let premium = WCVerifyService(whitelist: whitelist, premiumGate: StubGate(enabled: true))
        let free = WCVerifyService(whitelist: whitelist, premiumGate: StubGate(enabled: false))

        #expect(premium.defenseState(context: context(.valid)) == .safe)
        #expect(premium.defenseState(context: context(.valid, origin: "https://evil.example")) == .danger)
        #expect(premium.defenseState(context: context(.unknown)) == .danger)
        #expect(premium.defenseState(context: context(.scam)) == .scam)
        #expect(free.defenseState(context: context(.valid)) == .disabled)
        #expect(free.defenseState(context: context(.scam)) == .scam)

        whitelist.state = .loading
        #expect(premium.defenseState(context: context(.valid)) == .loading)
        whitelist.state = .unavailable
        #expect(premium.defenseState(context: context(.valid)) == .notAvailable)
    }

    @Test func sessionDefenseStateUsesPeerUrl() {
        let whitelist = StubWhitelist(domains: ["uniswap.org"])
        let premium = WCVerifyService(whitelist: whitelist, premiumGate: StubGate(enabled: true))
        let free = WCVerifyService(whitelist: whitelist, premiumGate: StubGate(enabled: false))

        #expect(premium.defenseState(peerUrl: origin) == .safe)
        #expect(premium.defenseState(peerUrl: "https://evil-uniswap.org") == .danger)
        #expect(free.defenseState(peerUrl: origin) == .disabled)

        whitelist.state = .loading
        #expect(premium.defenseState(peerUrl: origin) == .loading)
    }

    @Test func premiumOffKeepsVerifiedOnly() {
        let service = WCVerifyService(whitelist: StubWhitelist(domains: ["uniswap.org"]), premiumGate: StubGate(enabled: false))
        #expect(service.state(context: context(.valid)) == .verified(origin: origin))
    }
}

private final class StubWhitelist: IWCDappWhitelist {
    private let domains: [String]
    var state: WCWhitelistState

    init(domains: [String], state: WCWhitelistState = .loaded) {
        self.domains = domains
        self.state = state
    }

    func isTrusted(host: String) -> Bool {
        domains.contains { WCWhitelistMatcher.matches(host: host, allowed: $0) }
    }
}

private final class StubGate: IWCPremiumGate {
    let scamProtectionEnabled: Bool

    init(enabled: Bool) {
        scamProtectionEnabled = enabled
    }
}
