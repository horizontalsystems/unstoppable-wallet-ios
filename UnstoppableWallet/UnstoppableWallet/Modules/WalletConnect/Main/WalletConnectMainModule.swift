import UIKit
import RxCocoa

struct WalletConnectMainModule {

    public static func connect(uri: String) throws -> WalletConnectSession {
        fatalError()
//        //todo parse version and create appropriate service
//        let version: Int?
//        if uri.contains("@1?") {
//            let service = WalletConnectService(
//                    session: nil,
//                    uri: uri,
//                    manager: App.shared.walletConnectManager,
//                    sessionManager: App.shared.walletConnectSessionManager,
//                    reachabilityManager: App.shared.reachabilityManager
//            )
//
//            try service.connect(uri: uri)
//            return WalletConnectMainFactory(service: service)
//        } else if uri.contains("@2?") {
//            throw ConnectionError.unsupportedV2
//        } else {
//            throw ConnectionError.wrongUri
//        }
    }

}

extension WalletConnectMainModule {

    enum ConnectionError: Error {
        case wrongUri
        case unsupportedV2
    }

}