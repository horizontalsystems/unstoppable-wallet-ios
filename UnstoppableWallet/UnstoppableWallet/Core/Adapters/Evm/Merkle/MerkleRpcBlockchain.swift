import Foundation
import EvmKit
import HsToolKit
import MarketKit

public class MerkleRpcBlockchain {
    private let address: EvmKit.Address
    let chain: Chain
    private let syncer: IRpcSyncer
    private let manager: MerkleTransactionHashManager
    private let transactionBuilder: TransactionBuilder
    private var logger: Logger?

    init(address: EvmKit.Address,
         chain: Chain,
         manager: MerkleTransactionHashManager,
         syncer: IRpcSyncer,
         transactionBuilder: TransactionBuilder,
         logger: Logger? = nil
    ) {
        self.address = address
        self.chain = chain
        self.manager = manager
        self.syncer = syncer
        self.transactionBuilder = transactionBuilder
        self.logger = logger
    }
    
    deinit {
        print("Deinit MerkleRpcBlockchain!!!")
    }
}

extension MerkleRpcBlockchain: INonceProvider {
    public func start() {
        syncer.start()
    }
    
    public func stop() {
        syncer.stop()
    }

    public func nonce(defaultBlockParameter: DefaultBlockParameter = .pending) async throws -> Int {
        // sync only if needed pending/ because others will be same with main blockchain
        guard defaultBlockParameter.raw == DefaultBlockParameter.pending.raw else {
            return 0
        }

        let nonce: Int = try await syncer.fetch(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: defaultBlockParameter))
        logger?.log(level: .debug, message: "Send with nonce: \(nonce)")

        return nonce
    }

    public func send(rawTransaction: RawTransaction, signature: Signature) async throws -> Transaction {
        let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)

        let txHash = try await syncer.fetch(rpc: SendRawTransactionJsonRpc(signedTransaction: encoded))
        try manager.save(hash: MerkleTransactionHash(transactionHash: txHash, chainId: chain.id))

        logger?.log(level: .debug, message: "Send with txHASH: \(txHash.hs.hexString)")

        let tx = transactionBuilder.transaction(rawTransaction: rawTransaction, signature: signature)
        logger?.log(level: .debug, message: "TX \(tx.description)")
        return tx
    }

    public func transaction(transactionHash: Data) async throws -> RpcTransaction {
        let transaction: RpcTransaction = try await syncer.fetch(rpc: GetTransactionByHashJsonRpc(transactionHash: transactionHash))
        logger?.log(level: .debug, message: "Transaction -: \(transaction.description)")

        return transaction
    }
}

extension MerkleRpcBlockchain {
    public enum MerkleError: Error {
        case unsupportedChain
    }
}
