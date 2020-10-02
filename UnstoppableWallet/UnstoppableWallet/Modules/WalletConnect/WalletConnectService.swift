import EthereumKit
import WalletConnect

class WalletConnectService {
    var ethereumKit: Kit?

    var interactor: WalletConnectInteractor?
    var client: WalletConnectClient?

    init(ethereumKitManager: EthereumKitManager) {
        ethereumKit = ethereumKitManager.ethereumKit
        client = WalletConnectClient.storedInstance()
    }

    var isEthereumKitReady: Bool {
        ethereumKit != nil
    }

    var isClientReady: Bool {
        client != nil
    }

    func initInteractor(uri: String) throws {
        interactor = try WalletConnectInteractor(uri: uri)
    }

    func initClient(peerMeta: WCPeerMeta) throws {
        guard let interactor = interactor else {
            throw ClientError.noInteractor
        }

        client = WalletConnectClient(interactor: interactor, peerMeta: peerMeta)
    }

}

extension WalletConnectService {

    enum ClientError: Error {
        case noInteractor
    }

}
