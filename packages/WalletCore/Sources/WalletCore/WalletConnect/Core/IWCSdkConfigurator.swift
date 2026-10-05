import ReownWalletKit

// Slice over the SDK statics so the configuration order can be verified
protocol IWCSdkConfigurator: AnyObject {
    func configureNetworking(groupIdentifier: String, projectId: String)
    func configureWalletKit(metadata: AppMetadata)
    func setTelemetryEnabled(_ enabled: Bool)
}

class WCSdkConfigurator: IWCSdkConfigurator {
    func configureNetworking(groupIdentifier: String, projectId: String) {
        Networking.configure(groupIdentifier: groupIdentifier, projectId: projectId, socketFactory: WCSocketFactory(), socketConnectionType: .automatic)
    }

    func configureWalletKit(metadata: AppMetadata) {
        WalletKit.configure(metadata: metadata, crypto: WCCryptoProvider())
    }

    func setTelemetryEnabled(_ enabled: Bool) {
        Events.instance.setTelemetryEnabled(enabled)
    }
}
