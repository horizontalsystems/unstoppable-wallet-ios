import EthereumKit

class WalletConnectMainService {
    private let client: WalletConnectClient
    private let ethereumKit: Kit

    private init(client: WalletConnectClient, ethereumKit: Kit) {
        self.client = client
        self.ethereumKit = ethereumKit
    }

}

extension WalletConnectMainService: IWalletConnectInteractorDelegate {

    func didConnect() {
    }

    func didRequestSession() {
    }

}

extension WalletConnectMainService {

    static func instance(client: WalletConnectClient, ethereumKit: Kit) -> WalletConnectMainService {
        let service = WalletConnectMainService(client: client, ethereumKit: ethereumKit)
        client.interactor.delegate = service
        return service
    }

}
