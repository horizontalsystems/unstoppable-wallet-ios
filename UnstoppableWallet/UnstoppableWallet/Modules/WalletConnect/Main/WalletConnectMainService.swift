import EthereumKit
import WalletConnect

class WalletConnectMainService {
    private let client: WalletConnectClient
    private let ethereumKit: Kit

    init(client: WalletConnectClient, ethereumKit: Kit) {
        self.client = client
        self.ethereumKit = ethereumKit
    }

}

extension WalletConnectMainService: IWalletConnectInteractorDelegate {

    func didConnect() {
    }

    func didRequestSession(peerMeta: WCPeerMeta) {
    }

}
