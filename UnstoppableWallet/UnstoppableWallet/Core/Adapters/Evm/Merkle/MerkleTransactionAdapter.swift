import Foundation
import HsToolKit
import EvmKit
import MarketKit

class MerkleTransactionAdapter {
    static let blockchainPath: [Chain: String] = [
        .ethereum: "eth",
        .binanceSmartChain: "bsc",
        .base: "base"
    ]
    
    static let baseUrl: URL = URL(string: "https://mempool.merkle.io/rpc/")!
    static let apiPath: String = "pk_mbs_5f012edb2cf20a96b49429a3ed285a45"
    
    let blockchain: MerkleRpcBlockchain
    let syncer: ITransactionSyncer
    
    init?(address: EvmKit.Address, chain: Chain, logger: Logger?) {
        guard let blockchainPath = Self.blockchainPath[chain] else {
            return nil
        }

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
    }
    
    deinit {
        print("Deinit MerkleTransactionAdapter!!!")
    }
}

extension MerkleTransactionAdapter {
    func send(rawTransaction: RawTransaction, signature: Signature) async throws -> Transaction {
        let transaction = try await blockchain.send(rawTransaction: rawTransaction, signature: signature)
        return transaction
    }
}


