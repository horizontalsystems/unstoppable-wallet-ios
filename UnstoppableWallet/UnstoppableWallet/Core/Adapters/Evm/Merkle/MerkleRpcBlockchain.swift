import EvmKit
import Foundation
import HsToolKit
import MarketKit

public class MerkleRpcBlockchain {
    private let address: EvmKit.Address
    private let syncer: IRpcSyncer
    private let manager: MerkleTransactionHashManager
    private let transactionBuilder: TransactionBuilder
    private var logger: Logger?

    init(address: EvmKit.Address,
         manager: MerkleTransactionHashManager,
         syncer: IRpcSyncer,
         transactionBuilder: TransactionBuilder,
         logger: Logger? = nil)
    {
        self.address = address
        self.manager = manager
        self.syncer = syncer
        self.transactionBuilder = transactionBuilder
        self.logger = logger
    }
}

extension MerkleRpcBlockchain: INonceProvider {
    public func nonce(defaultBlockParameter: DefaultBlockParameter = .pending) async throws -> Int {
        // sync only if needed pending/ because others will be same with main blockchain
        guard defaultBlockParameter.raw == DefaultBlockParameter.pending.raw else {
            return 0
        }

        let nonce: Int = try await syncer.fetch(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: defaultBlockParameter))
        logger?.log(level: .debug, message: "Send with nonce: \(nonce)")

        return nonce
    }

    public func send(rawTransaction: RawTransaction, signature: Signature, sourceTag: String) async throws -> Transaction {
        let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)

        let txHash = try await syncer.fetch(rpc: MerkleSendRawTransactionJsonRpc(signedTransaction: encoded, sourceTag: sourceTag))
        try manager.save(hash: MerkleTransactionHash(transactionHash: txHash))

        logger?.log(level: .debug, message: "Send with txHASH: \(txHash.hs.hexString)")

        let tx = transactionBuilder.transaction(rawTransaction: rawTransaction, signature: signature)
        logger?.log(level: .debug, message: "TX \(tx.description)")
        return tx
    }

    public func cancel(hash: Data) async throws -> Bool {
        logger?.log(level: .debug, message: "Send Cancel txHASH: \(hash.hs.hexString)")

        let success = try await syncer.fetch(rpc: CancelTransactionJsonRpc(hash: hash))
        logger?.log(level: .debug, message: "Cancel result : \(hash.hs.hexString) | \(success)")
        return success
    }

    public func transaction(transactionHash: Data) async throws -> RpcTransaction? {
        let transaction: RpcTransaction? = try await syncer.fetch(rpc: MerkleGetTransactionByHashJsonRpc(transactionHash: transactionHash))
        logger?.log(level: .debug, message: "Found Transaction -: \(transaction?.description ?? "nil")")
        return transaction
    }
}
