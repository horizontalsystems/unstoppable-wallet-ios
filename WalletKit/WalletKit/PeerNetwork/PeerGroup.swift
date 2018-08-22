import Foundation
import RealmSwift
import RxSwift

class PeerGroup {

    struct PendingBlock {
        let headerHash: Data
        var pendingTransactionHashes: [Data]
        var transactions: [Transaction]
    }

    enum Status {
        case connected, disconnected
    }

    var statusSubject: PublishSubject<Status> = PublishSubject()
    weak var delegate: PeerGroupDelegate?

    private let realmFactory: RealmFactory

    private let peer: Peer

    private let validator = MerkleBlockValidator()
    private var pendingBlocks: [PendingBlock] = []

    init(realmFactory: RealmFactory, configuration: Configuration) {
        self.realmFactory = realmFactory
        self.peer = Peer(network: configuration.network)

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
        do {
            let headerHash = Crypto.sha256sha256(message.blockHeader.serialized())
            let hashes = try validator.validateAndGetTxHashes(message: message)

            if hashes.isEmpty {
                delegate?.peerGroupDidReceive(blockHeaderHash: headerHash, withTransactions: [])
            } else {
                pendingBlocks.append(PendingBlock(headerHash: headerHash, pendingTransactionHashes: hashes, transactions: []))
                print("TX COUNT: \(hashes.count)")
            }
        } catch {
            print("MERKLE BLOCK MESSAGE ERROR: \(error)")
        }
//        delegate?.peerGroupDidReceive(merkleBlock: message)
    }

    func peer(_ peer: Peer, didReceiveTransaction transaction: Transaction) {
        let txHash = Crypto.sha256sha256(transaction.serialized())

        if let index = pendingBlocks.index(where: { $0.pendingTransactionHashes.contains(txHash) }) {
            pendingBlocks[index].transactions.append(transaction)

            if pendingBlocks[index].transactions.count == pendingBlocks[index].pendingTransactionHashes.count {
                let block = pendingBlocks.remove(at: index)
                delegate?.peerGroupDidReceive(blockHeaderHash: block.headerHash, withTransactions: block.transactions)
            }

        } else {
            delegate?.peerGroupDidReceive(transaction: transaction)
        }
    }

    func peer(_ peer: Peer, didReceiveInventoryMessage message: InventoryMessage) {
        var items = [InventoryItem]()

        for item in message.inventoryItems {
            if let delegate = delegate, delegate.shouldRequest(inventoryItem: item) {
                items.append(item)
            }
        }

        if !items.isEmpty {
            let getDataMessage = InventoryMessage(count: VarInt(items.count), inventoryItems: items)
            peer.sendGetDataMessage(message: getDataMessage)
        }
    }

    func peer(_ peer: Peer, didReceiveGetDataMessage message: GetDataMessage) {
        for item in message.inventoryItems {
            if item.objectType == .transaction, let transaction = delegate?.transaction(forHash: item.hash) {
                peer.sendTransaction(transaction: transaction)
            }
        }
    }

    func peer(_ peer: Peer, didReceiveRejectMessage message: RejectMessage) {
    }

}
