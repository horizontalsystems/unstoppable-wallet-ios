import Combine
import RxCocoa
import RxSwift
import WalletConnectUtils

enum WalletConnectUriHandler {
    public static func validate(uri: String) throws {
        _ = try Core.shared.walletConnectSessionManager.service.validate(uri: uri)
    }

    public static func pair(uri: String) async throws {
        let uri = try Core.shared.walletConnectSessionManager.service.validate(uri: uri)
        try await Core.shared.walletConnectSessionManager.service.pair(uri: uri)
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
