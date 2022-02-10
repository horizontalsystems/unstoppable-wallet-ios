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

    private func createModuleV2(uri: String) -> Result<IWalletConnectXMainService, Error> {
        do {
            try App.shared.walletConnectV2SessionManager.service.pair(uri: uri)
        } catch {
            return .failure(error)
        }

        let service = App.shared.walletConnectV2SessionManager.service
        let pingService = WalletConnectV2PingService(service: service)
        let mainService = WalletConnectV2XMainService(
                session: nil,
                uri: uri,
                service: service,
                pingService: pingService,
                manager: App.shared.walletConnectManager,
                evmChainParser: WalletConnectEvmChainParser()
        )

        return .success(mainService)
    }

}

extension WalletConnectUriHandler {

    func connect(uri: String) -> Result<IWalletConnectXMainService, Error> {

        //todo parse version and create appropriate service
        let version: Int?
        if uri.contains("@1?") {
            return createModuleV1(uri: uri)
        } else if uri.contains("@2?") {
            return createModuleV2(uri: uri)
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
