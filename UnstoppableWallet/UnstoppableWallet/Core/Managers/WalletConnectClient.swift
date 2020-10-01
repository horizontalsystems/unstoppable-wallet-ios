import WalletConnect

class WalletConnectClient {
    let interactor: WalletConnectInteractor
    let peerMeta: WCPeerMeta

    private init(interactor: WalletConnectInteractor, peerMeta: WCPeerMeta) {
        self.interactor = interactor
        self.peerMeta = peerMeta
    }

}

extension WalletConnectClient {

    func connect() {
        interactor.connect()
    }

}

extension WalletConnectClient {

    static func instance(interactor: WalletConnectInteractor, peerMeta: WCPeerMeta) -> WalletConnectClient {
        WalletConnectClient(interactor: interactor, peerMeta: peerMeta)
    }

    static func storedInstance() -> WalletConnectClient? {
        guard let storeItem = WCSessionStore.allSessions.first?.value else {
            return nil
        }

        let interactor = WalletConnectInteractor.instance(session:storeItem.session)

        return WalletConnectClient(interactor: interactor, peerMeta: storeItem.peerMeta)
    }

}
