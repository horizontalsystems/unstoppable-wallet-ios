import Foundation
import ReownWalletKit
import Testing
@testable import WalletCore

struct WCNConfiguratorTests {
    private let info = WCNClientInfo(projectId: "pid", name: "Unstoppable", description: "", url: "https://unstoppable.money", icons: ["https://icon"], redirectScheme: "unstoppable.money://")

    @Test func telemetryIsDisabledBeforeAndAfterSdkConfiguration() throws {
        let suite = "wcn-configurator-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let sdk = SpyConfigurer(defaults: defaults)

        try WCNConfigurator(sdk: sdk, userDefaults: defaults).configure(info: info, bundleIdentifier: "io.horizontalsystems.bank-wallet")

        #expect(sdk.steps == ["networking(group.io.horizontalsystems.bank-wallet, pid)", "walletKit(Unstoppable)", "telemetry(false)"])
        #expect(sdk.telemetryKeyAtNetworkingConfigure == false)
        #expect(defaults.object(forKey: WCNConfigurator.telemetryKey) as? Bool == false)
    }

    @Test func metadataCarriesRedirectScheme() throws {
        let sdk = SpyConfigurer(defaults: .standard)
        try WCNConfigurator(sdk: sdk, userDefaults: .standard).configure(info: info, bundleIdentifier: "b")
        #expect(sdk.metadata?.redirect?.native == "unstoppable.money://")
        #expect(sdk.metadata?.url == "https://unstoppable.money")
    }
}

private final class SpyConfigurer: IWCNSdkConfigurer {
    private let defaults: UserDefaults
    private(set) var steps = [String]()
    private(set) var telemetryKeyAtNetworkingConfigure: Bool?
    private(set) var metadata: AppMetadata?

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func configureNetworking(groupIdentifier: String, projectId: String) {
        telemetryKeyAtNetworkingConfigure = defaults.object(forKey: WCNConfigurator.telemetryKey) as? Bool
        steps.append("networking(\(groupIdentifier), \(projectId))")
    }

    func configureWalletKit(metadata: AppMetadata) {
        self.metadata = metadata
        steps.append("walletKit(\(metadata.name))")
    }

    func setTelemetryEnabled(_ enabled: Bool) {
        steps.append("telemetry(\(enabled))")
    }
}
