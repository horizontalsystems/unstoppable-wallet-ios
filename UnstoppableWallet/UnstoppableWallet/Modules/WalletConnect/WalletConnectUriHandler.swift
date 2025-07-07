import Combine
import Foundation
import WalletConnectUtils
import Web3Wallet

enum WalletConnectUriHelper {
    public static func pair(uri: String) async throws {
        let uri = try validate(uri: uri)
        try await Web3Wallet.instance.pair(uri: uri)
    }

    public static func validate(uri: String) throws -> WalletConnectUtils.WalletConnectURI {
        guard let uri = try? WalletConnectUtils.WalletConnectURI(uriString: uri) else {
            throw WalletConnectUriHelper.ConnectionError.wrongUri
        }
        return uri
    }
}

extension WalletConnectUriHelper {
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

extension WalletConnectUriHelper {
    enum ConnectionError: Error, LocalizedError {
        case wrongUri
        case walletConnectDontRespond

        public var errorDescription: String? {
            switch self {
            case .wrongUri: return "wallet_connect.error.invalid_url".localized
            case .walletConnectDontRespond: return "alert.try_again".localized
            }
        }
    }
}
