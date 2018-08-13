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

    let syncSubject = BehaviorSubject<SyncStatus>(value: .synced)

    private var status: SyncStatus = .synced {
        didSet {
            syncSubject.onNext(status)
        }
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

    func peerGroupDidReceive(versionMessage message: VersionMessage) {
    }

    func peerGroupDidReceive(addressMessage message: AddressMessage) {
    }

    func peerGroupDidReceive(getDataMessage message: GetDataMessage) {
//        for item in getDataMessage.inventoryItems {
//            switch item.objectType {
//            case .error:
//                break
//            case .transaction:
//                // Send transaction
////                if let transaction = context.transactions[item.hash] {
////                    let payload = transaction.serialized()
////                    let checksum = Data(Crypto.sha256sha256(payload).prefix(4))
////
////                    let message = Message(magic: network.magic, command: "tx", length: UInt32(payload.count), checksum: checksum, payload: payload)
////                    sendMessage(message)
////                }
//                break
//            case .blockMessage:
//                break
//            case .filteredBlockMessage:
//                break
//            case .compactBlockMessage:
//                break
//            case .unknown:
//                break
//            }
//        }
    }

    func peerGroupDidReceive(inventoryMessage message: InventoryMessage) {
    }

    func peerGroupDidReceive(headersMessage message: HeadersMessage) {
        do {
            try headerHandler?.handle(headers: message.blockHeaders)
        } catch {
            print("Header Handler Error: \(error)")
        }
    }

    func peerGroupDidReceive(blockMessage message: BlockMessage) {
    }

    func peerGroupDidReceive(merkleBlockMessage message: MerkleBlockMessage) {
        do {
            try merkleBlockHandler?.handle(message: message)
        } catch {
            print("Merkle Block Handler Error: \(error)")
        }
    }

    func peerGroupDidReceive(rejectMessage message: RejectMessage) {
    }

    func peerGroupDidReceive(transaction: Transaction) {
        do {
            try transactionHandler?.handle(transaction: transaction)
        } catch {
            print("Transaction Handler Error: \(error)")
        }
    }

}
