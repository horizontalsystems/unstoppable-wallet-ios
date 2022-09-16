class WalletConnectUriHandler {

    private static func createModuleV1(uri: String) -> Result<IWalletConnectMainService, Error> {
        do {
            let service = try WalletConnectV1MainService(
                    session: nil,
                    uri: uri,
                    manager: App.shared.walletConnectManager,
                    sessionManager: App.shared.walletConnectSessionManager,
                    reachabilityManager: App.shared.reachabilityManager,
                    accountManager: App.shared.accountManager,
                    evmBlockchainManager: App.shared.evmBlockchainManager
            )
            return .success(service)
        } catch {
            return .failure(error)
        }
    }

    private static func createModuleV2(uri: String) -> Result<IWalletConnectMainService, Error> {
        do {
            try App.shared.walletConnectV2SessionManager.service.pair(uri: uri)
        } catch {
            return .failure(error)
        }

        let service = App.shared.walletConnectV2SessionManager.service
        let pingService = WalletConnectV2PingService(service: service, socketConnectionService: App.shared.walletConnectV2SocketConnectionService, logger: App.shared.logger)
        let mainService = WalletConnectV2MainService(
                session: nil,
                service: service,
                pingService: pingService,
                manager: App.shared.walletConnectManager,
                reachabilityManager: App.shared.reachabilityManager,
                accountManager: App.shared.accountManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                evmChainParser: WalletConnectEvmChainParser()
        )

        return .success(mainService)
    }

}

extension WalletConnectUriHandler {

    static func connect(uri: String) -> Result<IWalletConnectMainService, Error> {
        if uri.contains("@1?") {
            return createModuleV1(uri: uri)
        } else if uri.contains("@2?") {
            return createModuleV2(uri: uri)
        } else {
            return .failure(ConnectionError.wrongUri)
        }
    }

}

extension WalletConnectUriHandler {

    enum ConnectionError: Error {
        case wrongUri
    }

}
