import BigInt
import Combine
import EvmKit
import Foundation
import HsExtensions
import HsToolKit

class MerkleTransactionSyncer {
    private let manager: MerkleTransactionHashManager
    private let blockchain: MerkleRpcBlockchain
    private let logger: Logger?

    init(manager: MerkleTransactionHashManager, blockchain: MerkleRpcBlockchain, logger: Logger?) {
        self.manager = manager
        self.blockchain = blockchain
        self.logger = logger
    }

    weak var transactionFetcher: ITransactionFetcher?

    private func convert(tx: RpcTransaction) -> Transaction {
        Transaction(
            hash: tx.hash,
            timestamp: 0,
            isFailed: false,
            blockNumber: tx.blockNumber,
            transactionIndex: tx.transactionIndex,
            from: tx.from,
            to: tx.to,
            value: tx.value,
            input: tx.input,
            nonce: tx.nonce,
            gasPrice: tx.gasPrice,
            maxFeePerGas: tx.maxFeePerGas,
            maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
            gasLimit: tx.gasLimit,
            gasUsed: 0,
            replacedWith: nil
        )
    }

    private func fail(tx: Transaction) -> Transaction {
        Transaction(
            hash: tx.hash,
            timestamp: tx.timestamp,
            isFailed: true,
            blockNumber: tx.blockNumber,
            transactionIndex: tx.transactionIndex,
            from: tx.from,
            to: tx.to,
            value: tx.value,
            input: tx.input,
            nonce: tx.nonce,
            gasPrice: tx.gasPrice,
            maxFeePerGas: tx.maxFeePerGas,
            maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
            gasLimit: tx.gasLimit,
            gasUsed: tx.gasUsed,
            replacedWith: tx.replacedWith
        )
    }

    private func handleTransaction(hash: MerkleTransactionHash) async throws -> HandleTransactionResult {
        if let tx = try await blockchain.transaction(transactionHash: hash.transactionHash) {
            return .update(convert(tx: tx))
        }

        // merkle don't returns transaction. This is failed(cancelled)
        if let tx = transactionFetcher?.fullTransaction(hash: hash.transactionHash) {
            logger?.log(level: .debug, message: "Did Fail transaction with \(hash.transactionHash.hs.hexString)")
            return .fail(fail(tx: tx.transaction))
        }

        // if there is no tx in Db, just clear hash
        return .toRemove(hash)
    }
}

extension MerkleTransactionSyncer: ITransactionSyncer {
    func transactions() async throws -> ([Transaction], Bool) {
        guard manager.hasMerkleTransactions(),
              let hashes = try? manager.hashes()
        else {
            return ([], false)
        }

        var allTransactions: [Transaction] = []
        var failedTransactions: [Transaction] = []
        var removeUnused: [MerkleTransactionHash] = []

        for hash in hashes {
            let transactionResult = try await handleTransaction(hash: hash)
            switch transactionResult {
            case let .update(tx): allTransactions.append(tx)
            case let .fail(tx): failedTransactions.append(tx)
            case let .toRemove(hash): removeUnused.append(hash)
            }
        }

        allTransactions.append(contentsOf: failedTransactions)
        manager.handle(transactions: allTransactions, removeUnused: removeUnused)

        // we need to update only failed transactions
        return (failedTransactions, false)
    }
}

extension MerkleTransactionSyncer: IExtraDecorator {
    func extra(hash: Data) -> [String: Any] {
        logger?.log(level: .debug, message: "Ask about MEV protection! \(hash.hs.hexString)")

        guard manager.hasMerkleTransactions() else {
            return [:]
        }

        // if db has one of internal tx hashes, it's protected transaction
        do {
            let hashes = try manager.hashes()

            guard hashes.map(\.transactionHash).contains(hash) else {
                return [:]
            }
            logger?.log(level: .debug, message: "Set -Protected- for tx with \(hash.hs.hexString)")
            return [MerkleTransactionAdapter.protectedKey: true]
        } catch {
            return [:]
        }
    }
}

extension MerkleTransactionSyncer {
    enum HandleTransactionResult {
        case update(Transaction)
        case fail(Transaction)
        case toRemove(MerkleTransactionHash)
    }
}
