import RxSwift
import RxCocoa
import WalletConnectUtils

class WalletConnectUriHandler {

    public static func createServiceV1(uri: String) -> Single<WalletConnectV1MainService> {
        Single.create { observer in
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
                observer(.success(service))
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
    }


    public static func validate(uri: String) throws {
        _ = try App.shared.walletConnectV2SessionManager.service.validate(uri: uri)
    }

    public static func pairV2(uri: String) -> Single<()> {
        Single.create { observer in
            Task {
                do {
                    let uri = try App.shared.walletConnectV2SessionManager.service.validate(uri: uri)
                    try await App.shared.walletConnectV2SessionManager.service.pair(uri: uri)
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

}

extension WalletConnectUriHandler {

    static func uriVersion(uri: String) -> Int? {
        if uri.contains("@1?") {
            return 1
        } else if uri.contains("@2?") {
            return 2
        } else {
            return nil
        }
    }

}

extension WalletConnectUriHandler {

    enum ConnectionError: Error {
        case wrongUri
    }

}
