import Foundation
import ReownWalletKit

class WCNConfigurator {
    // the SDK's telemetry storage writes `true` on first access, so the key must exist before Networking.configure
    static let telemetryKey = "com.walletconnect.sdk.telemetryEnabled"

    private let sdk: IWCNSdkConfigurator
    private let userDefaults: UserDefaults

    init(sdk: IWCNSdkConfigurator, userDefaults: UserDefaults = .standard) {
        self.sdk = sdk
        self.userDefaults = userDefaults
    }

    func configure(info: WCNClientInfo, bundleIdentifier: String) throws {
        userDefaults.set(false, forKey: Self.telemetryKey)
        WCNLog.log("configurator: telemetry key set false")

        sdk.configureNetworking(groupIdentifier: "group.\(bundleIdentifier)", projectId: info.projectId)
        WCNLog.log("configurator: networking configured group=group.\(bundleIdentifier)")

        let metadata = try AppMetadata(
            name: info.name,
            description: info.description,
            url: info.url,
            icons: info.icons,
            redirect: AppMetadata.Redirect(native: info.redirectScheme, universal: nil)
        )
        sdk.configureWalletKit(metadata: metadata)
        WCNLog.log("configurator: walletkit configured name=\(info.name) redirect=\(info.redirectScheme)")

        sdk.setTelemetryEnabled(false)
        WCNLog.log("configurator: telemetry disabled")
    }
}
