import Foundation
import ReownWalletKit

class WCConfigurator {
    // the SDK's telemetry storage writes `true` on first access, so the key must exist before Networking.configure
    static let telemetryKey = "com.walletconnect.sdk.telemetryEnabled"

    private let sdk: IWCSdkConfigurator
    private let userDefaults: UserDefaults

    init(sdk: IWCSdkConfigurator, userDefaults: UserDefaults = .standard) {
        self.sdk = sdk
        self.userDefaults = userDefaults
    }

    func configure(info: WCClientInfo, bundleIdentifier: String) throws {
        userDefaults.set(false, forKey: Self.telemetryKey)
        WCLog.log("configurator: telemetry key set false")

        sdk.configureNetworking(groupIdentifier: "group.\(bundleIdentifier)", projectId: info.projectId)
        WCLog.log("configurator: networking configured group=group.\(bundleIdentifier)")

        let metadata = try AppMetadata(
            name: info.name,
            description: info.description,
            url: info.url,
            icons: info.icons,
            redirect: AppMetadata.Redirect(native: info.redirectScheme, universal: nil)
        )
        sdk.configureWalletKit(metadata: metadata)
        WCLog.log("configurator: walletkit configured name=\(info.name) redirect=\(info.redirectScheme)")

        sdk.setTelemetryEnabled(false)
        WCLog.log("configurator: telemetry disabled")
    }
}
