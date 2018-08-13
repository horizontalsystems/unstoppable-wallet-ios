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
//        print("Request Blocks: \(headerHashes.map { $0.reversedHex }.joined(separator: ", "))")
        let inventoryMessage = InventoryMessage(count: VarInt(headerHashes.count), inventoryItems: headerHashes.map { hash in
            InventoryItem(type: InventoryItem.ObjectType.filteredBlockMessage.rawValue, hash: hash)
        })

        peer.sendGetDataMessage(message: inventoryMessage)
    }

}

extension PeerGroup: PeerDelegate {

    func peerDidConnect(_ peer: Peer) {
        let realm = realmFactory.realm
        let addresses = realm.objects(Address.self)
        let filters = Array(addresses.map { $0.publicKeyHash }) + Array(addresses.map { $0.publicKey! })

        peer.load(filters: filters)
        peer.sendMemoryPoolMessage()

        statusSubject.onNext(.connected)

        delegate?.peerGroupDidConnect()
    }

    func peer(_ peer: Peer, didReceiveMerkleBlockMessage message: MerkleBlockMessage) {
//        print("MERKLE BLOCK: \(Crypto.sha256sha256(message.blockHeader.serialized()).reversedHex)")
        delegate?.peerGroupDidReceive(merkleBlockMessage: message)
    }

    func peer(_ peer: Peer, didReceiveTransaction transaction: Transaction) {
//        print("TRANSACTION: \(Crypto.sha256sha256(message.serialized()).reversedHex)")
        delegate?.peerGroupDidReceive(transaction: transaction)
    }

    func peer(_ peer: Peer, didReceiveHeadersMessage message: HeadersMessage) {
//        message.blockHeaders.first.map {
//            print("First Header: \(Data(Crypto.sha256sha256($0.serialized()).reversed()).hex)")
//        }
//        message.blockHeaders.last.map {
//            print("Last Header: \(Data(Crypto.sha256sha256($0.serialized()).reversed()).hex)")
//        }

        delegate?.peerGroupDidReceive(headersMessage: message)
    }

    func peer(_ peer: Peer, didReceiveInventoryMessage message: InventoryMessage) {
        var txInventoryItems = [InventoryItem]()
//        var hasBlock = false

        for item in message.inventoryItems {
            if item.objectType == .transaction {
                txInventoryItems.append(item)
            } else if item.objectType == .blockMessage {
//                hasBlock = true
            }
        }

        if !txInventoryItems.isEmpty {
            let getDataMessage = InventoryMessage(count: VarInt(txInventoryItems.count), inventoryItems: txInventoryItems)
            peer.sendGetDataMessage(message: getDataMessage)
        }

//        if hasBlock {
//            try? HeaderSyncer.shared.sync()
//        }
    }

}
