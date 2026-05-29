import BigInt
import EvmKit
import Foundation

struct WCEthereumTransaction: Codable {
    public let from: String
    public let to: String?
    public let nonce: String?
    public let gasPrice: String?
    public let gas: String?
    public let gasLimit: String? // legacy gas limit
    public let maxPriorityFeePerGas: String?
    public let maxFeePerGas: String?
    public let type: String?
    public let value: String?
    public let data: String
}

struct WalletConnectTransaction {
    let from: EvmKit.Address
    let to: EvmKit.Address
    let nonce: Int?
    let gasPrice: Int?
    let gasLimit: Int?
    let maxPriorityFeePerGas: Int?
    let maxFeePerGas: Int?
    let type: Int?
    let value: BigUInt
    let data: Data

    init(transaction: WCEthereumTransaction) throws {
        guard let to = transaction.to else {
            throw TransactionError.noRecipient
        }

        from = try EvmKit.Address(hex: transaction.from)
        self.to = try EvmKit.Address(hex: to)
        nonce = transaction.nonce.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) }
        gasPrice = transaction.gasPrice.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) }
        gasLimit = (transaction.gas ?? transaction.gasLimit).flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) }
        maxPriorityFeePerGas = transaction.maxPriorityFeePerGas.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) }
        maxFeePerGas = transaction.maxFeePerGas.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) }
        type = transaction.type.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) }
        value = transaction.value.flatMap { BigUInt($0.replacingOccurrences(of: "0x", with: ""), radix: 16) } ?? 0
        data = Data(hex: transaction.data)
    }
}

extension WalletConnectTransaction {
    enum TransactionError: Error {
        case noRecipient
    }
}
