class WalletConnectUriHandler {

    private static func createModuleV1(uri: String, completion: ((Result<IWalletConnectMainService, Error>) -> ())?) {
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
            completion?(.success(service))
        } catch {
            completion?(.failure(error))
        }
    }

    private static func createModuleV2(uri: String, completion: ((Result<IWalletConnectMainService, Error>) -> ())?) {
        Task {
            do {
                try await App.shared.walletConnectV2SessionManager.service.pair(uri: uri)

                let service = App.shared.walletConnectV2SessionManager.service
                let mainService = WalletConnectV2MainService(
                        session: nil,
                        service: service,
                        manager: App.shared.walletConnectManager,
                        reachabilityManager: App.shared.reachabilityManager,
                        accountManager: App.shared.accountManager,
                        evmBlockchainManager: App.shared.evmBlockchainManager,
                        evmChainParser: WalletConnectEvmChainParser()
                )

                completion?(.success(mainService))
            } catch {
                completion?(.failure(error))
            }
        }
    }

}

extension WalletConnectUriHandler {

    static func connect(uri: String, completion: ((Result<IWalletConnectMainService, Error>) -> ())?) {
            if uri.contains("@1?") {
                createModuleV1(uri: uri, completion: completion)
            } else if uri.contains("@2?") {
                createModuleV2(uri: uri, completion: completion)
            } else {
                completion?(.failure(ConnectionError.wrongUri))
            }
        }
    }

extension WalletConnectUriHandler {

    enum ConnectionError: Error {
        case wrongUri
    }

}
