class WalletConnectUriHandler {

    private func createModuleV1(uri: String) -> Result<IWalletConnectXMainService, Error> {
        let service = WalletConnectV1XMainService(
                session: nil,
                uri: uri,
                manager: App.shared.walletConnectManager,
                sessionManager: App.shared.walletConnectSessionManager,
                reachabilityManager: App.shared.reachabilityManager
        )

        do {
            try service.connect(uri: uri)
        } catch {
            return .failure(error)
        }

        return .success(service)
    }

}

extension WalletConnectUriHandler {

    func connect(uri: String) -> Result<IWalletConnectXMainService, Error> {

        //todo parse version and create appropriate service
        let version: Int?
        if uri.contains("@1?") {
            return createModuleV1(uri: uri)
        } else if uri.contains("@2?") {
            return  .failure(ConnectionError.unsupportedV2)
        } else {
            return  .failure(ConnectionError.wrongUri)
        }
    }

}

extension WalletConnectUriHandler {

    enum ConnectionError: Error {
        case unsupportedV2
        case wrongUri
    }

}
