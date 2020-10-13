import EthereumKit
import WalletConnect
import BigInt

class WalletConnectRequest {
    let id: Int

    init(id: Int) {
        self.id = id
    }

}

class WalletConnectSendEthereumTransactionRequest: WalletConnectRequest {
    let transaction: Transaction

    init(id: Int, transaction: WCEthereumTransaction) throws {
        guard let to = transaction.to else {
            throw TransactionError.invalidRecipient
        }

        guard let gasLimitString = transaction.gas ?? transaction.gasLimit, let gasLimit = Int(gasLimitString.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            throw TransactionError.invalidGasLimit
        }

        guard let valueString = transaction.value, let value = BigUInt(valueString.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            throw TransactionError.invalidValue
        }

        guard let data = Data(hex: transaction.data) else {
            throw TransactionError.invalidData
        }

        self.transaction = Transaction(
                from: try Address(hex: transaction.from),
                to: try Address(hex: to),
                nonce: transaction.nonce.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasPrice: transaction.gasPrice.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasLimit: gasLimit,
                value: value,
                data: data
        )

        super.init(id: id)
    }

    struct Transaction {
        let from: Address
        let to: Address
        let nonce: Int?
        let gasPrice: Int?
        let gasLimit: Int
        let value: BigUInt
        let data: Data
    }

    enum TransactionError: Error {
        case unsupportedRequestType
        case invalidRecipient
        case invalidGasLimit
        case invalidValue
        case invalidData
    }

}
