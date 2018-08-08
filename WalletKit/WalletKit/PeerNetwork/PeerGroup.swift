import Foundation
import RealmSwift
import RxSwift

class PeerGroup {
    static let shared = PeerGroup()

    enum Status {
        case connected, disconnected
    }

    var statusSubject: PublishSubject<Status> = PublishSubject()

    private let peer = Peer(network: TestNet())

    init() {
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

    public func peerDidConnect(_ peer: Peer) {
        let realm = RealmFactory.shared.realm
        let addresses = realm.objects(Address.self)
        let filters = Array(addresses.map { $0.publicKeyHash }) + Array(addresses.map { $0.publicKey! })

        peer.load(filters: filters)
        peer.sendMemoryPoolMessage()

        statusSubject.onNext(.connected)

        do {
            try HeaderSyncer.shared.sync()
        } catch {
            print("HeaderSyncer error: \(error)")
        }
    }

    public func peer(_ peer: Peer, didReceiveMerkleBlockMessage message: MerkleBlockMessage) {
//        print("MERKLE BLOCK: \(Crypto.sha256sha256(message.blockHeader.serialized()).reversedHex)")

        do {
            try MerkleBlockHandler.shared.handle(message: message)
        } catch {
            print("MerkleBlockHandler error: \(error)")
        }
    }

    public func peer(_ peer: Peer, didReceiveTransaction message: Transaction) {
//        print("TRANSACTION: \(Crypto.sha256sha256(message.serialized()).reversedHex)")

        do {
            try TransactionHandler.shared.handle(transaction: message)
        } catch {
            print("TransactionHandler error: \(error)")
        }
    }

    public func peer(_ peer: Peer, didReceiveHeadersMessage message: HeadersMessage) {
//        message.blockHeaders.first.map {
//            print("First Header: \(Data(Crypto.sha256sha256($0.serialized()).reversed()).hex)")
//        }
//        message.blockHeaders.last.map {
//            print("Last Header: \(Data(Crypto.sha256sha256($0.serialized()).reversed()).hex)")
//        }

        if !message.blockHeaders.isEmpty {
            do {
                try HeaderHandler.shared.handle(headers: message.blockHeaders)
            } catch {
                print("HeaderHandler error: \(error)")
            }
        }
    }

    func peer(_ peer: Peer, didReceiveInventoryMessage message: InventoryMessage) {
        var txInventoryItems = [InventoryItem]()
        var hasBlock = false

        for item in message.inventoryItems {
            if item.objectType == .transaction {
                txInventoryItems.append(item)
            } else if item.objectType == .blockMessage {
                hasBlock = true
            }
        }

        if !txInventoryItems.isEmpty {
            let getDataMessage = InventoryMessage(count: VarInt(txInventoryItems.count), inventoryItems: txInventoryItems)
            peer.sendGetDataMessage(message: getDataMessage)
        }

        if hasBlock {
            try? HeaderSyncer.shared.sync()
        }
    }

}
