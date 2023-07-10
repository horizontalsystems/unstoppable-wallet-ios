import Foundation
import EvmKit
import WalletConnectV1
import BigInt

class WalletConnectRequest {
    let id: Int
    let chain: Chain
    let dAppName: String?

    init(id: Int, chain: Chain, dAppName: String?) {
        self.id = id
        self.chain = chain
        self.dAppName = dAppName
    }

    func convert(result: Any) -> String? {
        nil
    }

    struct Chain {
        let id: Int
        let chainName: String?
        let address: String?

        init(id: Int, chainName: String? = nil, address: String? = nil) {
            self.id = id
            self.chainName = chainName
            self.address = address
        }

    }

}

class WalletConnectSendEthereumTransactionRequest: WalletConnectRequest {
    let transaction: WalletConnectTransaction

    init(id: Int, chain: WalletConnectRequest.Chain, dAppName: String?, transaction: WCEthereumTransaction) throws {
        guard let to = transaction.to else {
            throw TransactionError.noRecipient
        }

        self.transaction = WalletConnectTransaction(
                from: try EvmKit.Address(hex: transaction.from),
                to: try EvmKit.Address(hex: to),
                nonce: transaction.nonce.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasPrice: transaction.gasPrice.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasLimit: (transaction.gas ?? transaction.gasLimit).flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                maxPriorityFeePerGas: transaction.maxPriorityFeePerGas.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                maxFeePerGas: transaction.maxFeePerGas.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                type: transaction.type.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                value: transaction.value.flatMap { BigUInt($0.replacingOccurrences(of: "0x", with: ""), radix: 16) } ?? 0,
                data: Data(hex: transaction.data)
        )

        super.init(id: id, chain: chain, dAppName: dAppName)
    }

    override func convert(result: Any) -> String? {
        (result as? Data)?.hs.hexString
    }

    enum TransactionError: Error {
        case noRecipient
    }

}

class WalletConnectSignMessageRequest: WalletConnectRequest {
    let payload: WCEthereumSignPayload

    init(id: Int, chain: WalletConnectRequest.Chain, dAppName: String?, payload: WCEthereumSignPayload) {
        self.payload = payload

        super.init(id: id, chain: chain, dAppName: dAppName)
    }

    override func convert(result: Any) -> String? {
        (result as? Data)?.hs.hexString
    }

}
