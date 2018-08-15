import Foundation
import RealmSwift
import RxSwift

class PeerGroup {

    enum Status {
        case connected, disconnected
    }

    var statusSubject: PublishSubject<Status> = PublishSubject()
    weak var delegate: PeerGroupDelegate?

    private let realmFactory: RealmFactory

    private let peer = Peer(network: TestNet())

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory

        peer.delegate = self
    }

    func connect() {
        peer.connect()
    }

    func requestHeaders(headerHashes: [Data]) {
        peer.sendGetHeadersMessage(headerHashes: headerHashes)
    }

    func requestBlocks(headerHashes: [Data]) {
        let inventoryMessage = InventoryMessage(count: VarInt(headerHashes.count), inventoryItems: headerHashes.map { hash in
            InventoryItem(type: InventoryItem.ObjectType.filteredBlockMessage.rawValue, hash: hash)
        })

        peer.sendGetDataMessage(message: inventoryMessage)
    }

    func relay(transaction: Transaction) {
        let inventoryMessage = InventoryMessage(count: VarInt(1), inventoryItems: [
            InventoryItem(type: InventoryItem.ObjectType.transaction.rawValue, hash: Crypto.sha256sha256(transaction.serialized()))
        ])

        peer.send(inventoryMessage: inventoryMessage)
    }

}

extension PeerGroup: PeerDelegate {

    func peerDidConnect(_ peer: Peer) {
        let realm = realmFactory.realm
        let pubKeys = realm.objects(PublicKey.self)
        let filters = Array(pubKeys.map { $0.keyHash }) + Array(pubKeys.map { $0.raw! })

        peer.load(filters: filters)
        peer.sendMemoryPoolMessage()

        statusSubject.onNext(.connected)

        delegate?.peerGroupDidConnect()
    }

    func peerDidDisconnect(_ peer: Peer) {
    }

    func peer(_ peer: Peer, didReceiveAddressMessage message: AddressMessage) {
    }

    func peer(_ peer: Peer, didReceiveHeadersMessage message: HeadersMessage) {
        delegate?.peerGroupDidReceive(headers: message.blockHeaders)
    }

    func peer(_ peer: Peer, didReceiveMerkleBlockMessage message: MerkleBlockMessage) {
        delegate?.peerGroupDidReceive(merkleBlock: message)
    }

    func peer(_ peer: Peer, didReceiveTransaction transaction: Transaction) {
        delegate?.peerGroupDidReceive(transaction: transaction)
    }

    func peer(_ peer: Peer, didReceiveInventoryMessage message: InventoryMessage) {
    }

    func peer(_ peer: Peer, didReceiveGetDataMessage message: GetDataMessage) {
    }

    func peer(_ peer: Peer, didReceiveRejectMessage message: RejectMessage) {
    }

}
