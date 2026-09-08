import Combine
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
        Networking.instance.setLogging(level: .debug)
        Networking.instance.socketConnectionStatusPublisher
            .sink { WCLog.log("sdk socket status: \($0)") }
            .store(in: &WCLog.cancellables)
    }

    func configureWalletKit(metadata: AppMetadata) {
        WalletKit.configure(metadata: metadata, crypto: WCCryptoProvider())
        Sign.instance.setLogging(level: .debug)
    }

    func setTelemetryEnabled(_ enabled: Bool) {
        Events.instance.setTelemetryEnabled(enabled)
    }
}
