import EvmKit
import Foundation
import HsToolKit
import MarketKit

class MerkleTransactionAdapter {
    static let blockchainPath: [Chain: String] = [
        .ethereum: "eth",
        .binanceSmartChain: "bsc",
        .base: "base",
    ]

    static let baseUrl: URL = .init(string: "https://mempool.merkle.io/rpc/")!
    static let apiPath: String = "pk_mbs_5f012edb2cf20a96b49429a3ed285a45"

    static let protectedKey = "protected"

    let blockchain: MerkleRpcBlockchain
    let syncer: MerkleTransactionSyncer
    let transactionManager: TransactionManager

    init?(transactionManager: TransactionManager, address: EvmKit.Address, chain: Chain, logger: Logger?) {
        guard let blockchainPath = Self.blockchainPath[chain] else {
            return nil
        }

        self.transactionManager = transactionManager

        let url = Self.baseUrl.appending(path: blockchainPath).appending(path: Self.apiPath)
        let rpcProvider = NodeApiProvider(
            networkManager: Core.shared.networkManager,
            urls: [url],
            auth: nil
        )

        let rpcSyncer = ApiRpcSyncer(
            rpcApiProvider: rpcProvider,
            reachabilityManager: Core.shared.reachabilityManager,
            syncInterval: chain.syncInterval
        )

        let transactionBuilder = TransactionBuilder(chain: chain, address: address)

        blockchain = MerkleRpcBlockchain(
            address: address,
            chain: chain,
            manager: Core.shared.merkleTransactionHashManager,
            syncer: rpcSyncer,
            transactionBuilder: transactionBuilder
        )

        syncer = MerkleTransactionSyncer(
            manager: Core.shared.merkleTransactionHashManager,
            blockchain: blockchain,
            logger: logger
        )

        syncer.transactionFetcher = transactionManager
    }

    deinit {
        print("Deinit MerkleTransactionAdapter!!!")
    }
}

extension MerkleTransactionAdapter {
    func send(rawTransaction: RawTransaction, signature: Signature) async throws -> FullTransaction {
        let transaction = try await blockchain.send(rawTransaction: rawTransaction, signature: signature)
        let fullTransactions = transactionManager.handle(transactions: [transaction])
        return fullTransactions[0]
    }

    func cancel(hash: Data) async throws -> Bool {
        try await blockchain.cancel(hash: hash)
    }
}

extension MerkleTransactionAdapter {
    static func isProtected(transaction: FullTransaction) -> Bool {
        (transaction.extra[protectedKey] as? Bool) ?? false
    }

    static func allowProtection(chain: Chain) -> Bool {
        blockchainPath[chain] != nil
    }
}

protocol ITransactionFetcher: AnyObject {
    func fullTransaction(hash: Data) -> FullTransaction?
}

extension TransactionManager: ITransactionFetcher {}
