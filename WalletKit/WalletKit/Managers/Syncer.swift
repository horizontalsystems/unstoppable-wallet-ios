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

    private let logger: Logger
    private let realmFactory: RealmFactory

    let syncSubject = BehaviorSubject<SyncStatus>(value: .synced)

    private var status: SyncStatus = .synced {
        didSet {
            syncSubject.onNext(status)
        }
    }

    init(logger: Logger, realmFactory: RealmFactory) {
        self.logger = logger
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
            logger.log(tag: "Header Syncer Error", message: "\(error)")
        }
    }

    func peerGroupDidDisconnect() {
    }

    func peerGroupDidReceive(headers: [BlockHeader]) {
        do {
            try headerHandler?.handle(headers: headers)
        } catch {
            logger.log(tag: "Header Handler Error", message: "\(error)")
        }
    }

    func peerGroupDidReceive(merkleBlock: MerkleBlockMessage) {
        do {
            try merkleBlockHandler?.handle(message: merkleBlock)
        } catch {
            logger.log(tag: "Merkle Block Handler Error", message: "\(error)")
        }
    }

    func peerGroupDidReceive(transaction: Transaction) {
        do {
            try transactionHandler?.handle(transaction: transaction)
        } catch {
            logger.log(tag: "Transaction Handler Error", message: "\(error)")
        }
    }

    func shouldRequest(inventoryItem: InventoryItem) -> Bool {
        fatalError("shouldRequest(inventoryItem:) has not been implemented")
    }

    func transaction(forHash hash: Data) -> Transaction? {
        fatalError("transaction(hash:) has not been implemented")
    }

}
