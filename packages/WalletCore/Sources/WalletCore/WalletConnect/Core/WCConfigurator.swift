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

        sdk.configureNetworking(groupIdentifier: "group.\(bundleIdentifier)", projectId: info.projectId)

        let metadata = try AppMetadata(
            name: info.name,
            description: info.description,
            url: info.url,
            icons: info.icons,
            redirect: AppMetadata.Redirect(native: info.redirectScheme, universal: nil)
        )
        sdk.configureWalletKit(metadata: metadata)

        sdk.setTelemetryEnabled(false)
    }
}
