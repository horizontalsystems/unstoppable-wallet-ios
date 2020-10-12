import WalletConnect
import RxSwift
import RxRelay

class WalletConnectSessionStore {
    private let storedPeerMetaRelay = PublishRelay<WCPeerMeta?>()

    var storedItem: WCSessionStoreItem? {
        WCSessionStore.allSessions.first?.value
    }

    var storedPeerMeta: WCPeerMeta? {
        storedItem?.peerMeta
    }

    var storedPeerMetaObservable: Observable<WCPeerMeta?> {
        storedPeerMetaRelay.asObservable()
    }

    func store(session: WCSession, peerId: String, peerMeta: WCPeerMeta) {
        WCSessionStore.store(session, peerId: peerId, peerMeta: peerMeta)

        storedPeerMetaRelay.accept(peerMeta)
    }

    func clear() {
        WCSessionStore.clearAll()

        storedPeerMetaRelay.accept(nil)
    }

}
