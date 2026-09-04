import ReownWalletKit

// Slice over the SDK statics so the configuration order can be verified
protocol IWCNSdkConfigurator: AnyObject {
    func configureNetworking(groupIdentifier: String, projectId: String)
    func configureWalletKit(metadata: AppMetadata)
    func setTelemetryEnabled(_ enabled: Bool)
}

class WCNSdkConfigurator: IWCNSdkConfigurator {
    func configureNetworking(groupIdentifier: String, projectId: String) {
        Networking.configure(groupIdentifier: groupIdentifier, projectId: projectId, socketFactory: WCNSocketFactory(), socketConnectionType: .automatic)
    }

    func configureWalletKit(metadata: AppMetadata) {
        WalletKit.configure(metadata: metadata, crypto: WCNCryptoProvider())
    }

    func setTelemetryEnabled(_ enabled: Bool) {
        Events.instance.setTelemetryEnabled(enabled)
    }
}
