import RxSwift
import RxCocoa
import WalletConnectUtils

class WalletConnectUriHandler {

    public static func validate(uri: String) throws {
        _ = try App.shared.walletConnectSessionManager.service.validate(uri: uri)
    }

    public static func pair(uri: String) -> Single<()> {
        Single.create { observer in
            Task {
                do {
                    let uri = try App.shared.walletConnectSessionManager.service.validate(uri: uri)
                    try await App.shared.walletConnectSessionManager.service.pair(uri: uri)
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
