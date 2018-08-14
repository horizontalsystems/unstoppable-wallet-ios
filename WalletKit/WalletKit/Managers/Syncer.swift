import Foundation
import RxSwift
import RealmSwift

class Syncer {

    enum SyncStatus {
        case syncing
        case synced
        case error
    }

    weak var headerSyncer: HeaderSyncer?
    weak var headerHandler: HeaderHandler?
    weak var merkleBlockHandler: MerkleBlockHandler?
    weak var transactionHandler: TransactionHandler?

    private let realmFactory: RealmFactory

    let syncSubject = BehaviorSubject<SyncStatus>(value: .synced)

    private var status: SyncStatus = .synced {
        didSet {
            syncSubject.onNext(status)
        }
    }

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory
    }

    private func initialSync() {
        status = .syncing
    }

}

extension Syncer: PeerGroupDelegate {

    func peerGroupDidConnect() {
        do {
            try headerSyncer?.sync()
        } catch {
            print("Header Syncer Error: \(error)")
        }
    }

    func peerGroupDidDisconnect() {
    }

    func peerGroupDidReceive(getDataMessage message: GetDataMessage, peer: Peer) {
        for item in message.inventoryItems {
            switch item.objectType {
            case .error:
                break
            case .transaction:
                if let transaction = realmFactory.realm.objects(Transaction.self).filter("reversedHashHex = %@", item.hash.reversedHex).first {
                    peer.sendTransaction(transaction: transaction)
                }
                break
            case .blockMessage:
                break
            case .filteredBlockMessage:
                break
            case .compactBlockMessage:
                break
            case .unknown:
                break
            }
        }
    }

    func peerGroupDidReceive(inventoryMessage message: InventoryMessage, peer: Peer) {
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
//            syncHeaders()
//        }
    }

    func peerGroupDidReceive(headersMessage message: HeadersMessage, peer: Peer) {
        do {
            try headerHandler?.handle(headers: message.blockHeaders)
        } catch {
            print("Header Handler Error: \(error)")
        }
    }

    func peerGroupDidReceive(merkleBlockMessage message: MerkleBlockMessage, peer: Peer) {
        do {
            try merkleBlockHandler?.handle(message: message)
        } catch {
            print("Merkle Block Handler Error: \(error)")
        }
    }

    func peerGroupDidReceive(transaction: Transaction, peer: Peer) {
        do {
            try transactionHandler?.handle(transaction: transaction)
        } catch {
            print("Transaction Handler Error: \(error)")
        }
    }

}
