import EvmKit
import Foundation
import GRDB
import HsToolKit
import MarketKit

class MerkleTransactionAdapter {
    static let blockchainPath: [Chain: String] = [
        .ethereum: "eth",
        .binanceSmartChain: "bsc",
        .base: "base",
    ]

    static let baseUrl: URL = .init(string: "https://mempool.merkle.io/rpc/")!
    static let sourceTag = "unstoppable-wallet-ios"
    static let protectedKey = "protected"

    let merkleTransactionHashManager: MerkleTransactionHashManager
    let blockchain: MerkleRpcBlockchain
    let syncer: MerkleTransactionSyncer

    let transactionManager: TransactionManager

    init?(transactionManager: TransactionManager, address: EvmKit.Address, chain: Chain, walletId: String, logger: Logger?) {
        guard let blockchainPath = Self.blockchainPath[chain] else {
            return nil
        }

        self.transactionManager = transactionManager

        let url = Self.baseUrl.appending(path: blockchainPath).appending(path: AppConfig.merkleApiPath)
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

        do {
            let uniqueId = "\(walletId)-\(chain.id)"
            let merkleTransactionHashStorage = try MerkleTransactionHashStorage(databaseDirectoryUrl: Self.dataDirectoryUrl(), databaseFileName: "hash-\(uniqueId)")

            merkleTransactionHashManager = MerkleTransactionHashManager(storage: merkleTransactionHashStorage, logger: logger)

            blockchain = MerkleRpcBlockchain(
                address: address,
                manager: merkleTransactionHashManager,
                syncer: rpcSyncer,
                transactionBuilder: transactionBuilder
            )

            syncer = MerkleTransactionSyncer(
                manager: merkleTransactionHashManager,
                blockchain: blockchain,
                logger: logger
            )

            syncer.transactionFetcher = transactionManager
        } catch {
            logger?.log(level: .error, message: "Can't create Adapter because: \(error)")
            return nil
        }
    }
}

extension MerkleTransactionAdapter {
    func send(rawTransaction: RawTransaction, signature: Signature) async throws -> FullTransaction {
        let transaction = try await blockchain.send(rawTransaction: rawTransaction, signature: signature, sourceTag: Self.sourceTag)
        let fullTransactions = transactionManager.handle(transactions: [transaction])
        return fullTransactions[0]
    }

    func cancel(hash: Data) async throws -> Bool {
        try await blockchain.cancel(hash: hash)
    }
}

extension MerkleTransactionAdapter {
    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("merkle-mev-protection", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

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
