import EvmKit
import Foundation
import HsToolKit

class MerkleTransactionHashManager {
    private let storage: MerkleTransactionHashStorage
    private let logger: Logger?

    private var _hasMerkleTransactions: Bool?

    func hasMerkleTransactions() -> Bool {
        if let hasTxs = _hasMerkleTransactions {
            return hasTxs
        }

        do {
            let hashes = try storage.hashes()
            let hasTxs = !hashes.isEmpty
            _hasMerkleTransactions = hasTxs

            return hasTxs
        } catch {
            logger?.log(level: .debug, message: "Can't Parse hashes, returns false")
            return false
        }
    }

    init(storage: MerkleTransactionHashStorage, logger: Logger?) {
        self.storage = storage
        self.logger = logger
    }
}

extension MerkleTransactionHashManager {
    func hashes() throws -> [MerkleTransactionHash] {
        try storage.hashes()
    }

    func save(hash: MerkleTransactionHash) throws {
        try storage.save(hash: hash)
        _hasMerkleTransactions = true
    }

    func handle(transactions: [Transaction], removeUnused: [MerkleTransactionHash]) {
        do {
            let hashes = try storage.hashes()

            var toRemove: [MerkleTransactionHash] = transactions.compactMap { tx in
                tx.blockNumber != nil || tx.isFailed ? MerkleTransactionHash(transactionHash: tx.hash) : nil
            }

            toRemove.append(contentsOf: removeUnused)

            if !toRemove.isEmpty {
                let deletedCount = try storage.delete(hashes: toRemove)
                logger?.log(level: .debug, message: "Delete txHashes: \(deletedCount)")

                _hasMerkleTransactions = deletedCount < hashes.count // when we delete all hashes, set flag to false
            }
        } catch {
            logger?.log(level: .debug, message: "Can't Parse hashes, do nothing")
        }
    }
}
