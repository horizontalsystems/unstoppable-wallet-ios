import EvmKit
import Foundation
import HsToolKit
import HsExtensions
import Combine

class MerkleTransactionSyncer {
    private let syncerId = "merkle-transaction-syncer"
    private var cancellables = Set<AnyCancellable>()

    private let manager: MerkleTransactionHashManager
    private let blockchain: MerkleRpcBlockchain
    private let logger: Logger?

    init(manager: MerkleTransactionHashManager, blockchain: MerkleRpcBlockchain, logger: Logger?) {
        self.manager = manager
        self.blockchain = blockchain
        self.logger = logger
    }
    
    deinit {
        print("Deinit MerkleTransactionSyncer!!!")
    }

    
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
}

extension MerkleTransactionSyncer: ITransactionSyncer {
    func transactions() async throws -> ([Transaction], Bool) {
        guard manager.hasMerkleTransactions(chainId: blockchain.chain.id),
              let hashes = try? manager.hashes(chainId: blockchain.chain.id) else {

            return ([], false)
        }
        
        var transactions: [Transaction] = []
        for hash in hashes {
            let tx = try await blockchain.transaction(transactionHash: hash.transactionHash)
            logger?.log(level: .debug, message: "TXSyncer FounD TX: \(tx.description)")
            transactions.append(convert(tx: tx))
        }
        
        manager.handle(transactions: transactions, chainId: blockchain.chain.id)
        return (transactions, false)
    }
}
