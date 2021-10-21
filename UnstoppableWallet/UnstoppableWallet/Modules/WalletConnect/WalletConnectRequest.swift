import EthereumKit
import WalletConnectV1
import BigInt

class WalletConnectRequest {
    let id: Int

    init(id: Int) {
        self.id = id
    }

    func convert(result: Any) -> String? {
        nil
    }

}

class WalletConnectSendEthereumTransactionRequest: WalletConnectRequest {
    let transaction: WalletConnectTransaction

    init(id: Int, transaction: WCEthereumTransaction) throws {
        guard let to = transaction.to else {
            throw TransactionError.noRecipient
        }

        self.transaction = WalletConnectTransaction(
                from: try EthereumKit.Address(hex: transaction.from),
                to: try EthereumKit.Address(hex: to),
                nonce: transaction.nonce.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasPrice: transaction.gasPrice.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasLimit: (transaction.gas ?? transaction.gasLimit).flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                value: transaction.value.flatMap { BigUInt($0.replacingOccurrences(of: "0x", with: ""), radix: 16) } ?? 0,
                data: Data(hex: transaction.data)
        )

        super.init(id: id)
    }

    override func convert(result: Any) -> String? {
        (result as? Data)?.toHexString()
    }

    enum TransactionError: Error {
        case noRecipient
    }

}

class WalletConnectSignMessageRequest: WalletConnectRequest {
    let payload: WCEthereumSignPayload

    init(id: Int, payload: WCEthereumSignPayload) {
        self.payload = payload

        super.init(id: id)
    }

    override func convert(result: Any) -> String? {
        (result as? Data)?.toHexString()
    }

}
