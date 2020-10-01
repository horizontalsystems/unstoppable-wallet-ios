import EthereumKit

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
        interactor = try WalletConnectInteractor.instance(uri: uri)
    }

}
