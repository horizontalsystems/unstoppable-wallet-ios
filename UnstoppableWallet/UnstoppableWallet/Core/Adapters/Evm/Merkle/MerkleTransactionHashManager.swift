import EvmKit
import Foundation
import HsToolKit

class MerkleTransactionHashManager {
    private let storage: MerkleTransactionHashStorage
    private let logger: Logger?

    private var _hasMerkleTransactions: [Int: Bool] = [:]

    func hasMerkleTransactions(chainId: Int) -> Bool {
        if let hasTxs = _hasMerkleTransactions[chainId] {
            return hasTxs
        }

        do {
            let hashes = try storage.hashes(chainId: chainId)
            let hasTxs = !hashes.isEmpty
            _hasMerkleTransactions[chainId] = hasTxs

            return hasTxs
        } catch {
            print("Can't Parse hashes, returns false")
            return false
        }
    }

    init(storage: MerkleTransactionHashStorage, logger: Logger?) {
        self.storage = storage
        self.logger = logger
    }
}

extension MerkleTransactionHashManager {
    func hashes(chainId: Int) throws -> [MerkleTransactionHash] {
        try storage.hashes(chainId: chainId)
    }

    func save(hash: MerkleTransactionHash) throws {
        try storage.save(hash: hash)
        _hasMerkleTransactions[hash.chainId] = true
    }

    func handle(transactions: [Transaction], removeUnused: [MerkleTransactionHash], chainId: Int) {
        do {
            let hashes = try storage.hashes(chainId: chainId)

            var toRemove: [MerkleTransactionHash] = transactions.compactMap { tx in
                tx.blockNumber != nil || tx.isFailed ? MerkleTransactionHash(transactionHash: tx.hash, chainId: chainId) : nil
            }

            toRemove.append(contentsOf: removeUnused)

            if !toRemove.isEmpty {
                let deletedCount = try storage.delete(hashes: toRemove)
                logger?.log(level: .debug, message: "Delete txHashes: \(deletedCount)")

                _hasMerkleTransactions[chainId] = deletedCount < hashes.count // when we delete all hashes, set flag to false
            }
        } catch {
            print("Can't Parse hashes, do nothing")
        }
    }
}
