import BigInt
import EvmKit
import Foundation
import WalletConnectSign

struct WCNEvmTransaction: Equatable {
    let from: EvmKit.Address
    let to: EvmKit.Address
    let nonce: Int?
    let gasPrice: Int?
    let gasLimit: Int?
    let maxPriorityFeePerGas: Int?
    let maxFeePerGas: Int?
    let value: BigUInt
    let data: Data

    static func parse(params: AnyCodable) throws -> WCNEvmTransaction {
        guard let raw = try? params.get([WCNEvmRawTransaction].self).first else {
            throw ParsingError.malformedParams
        }
        return try WCNEvmTransaction(raw: raw)
    }

    init(raw: WCNEvmRawTransaction) throws {
        guard let to = raw.to else {
            throw ParsingError.noRecipient
        }

        from = try EvmKit.Address(hex: raw.from)
        self.to = try EvmKit.Address(hex: to)
        nonce = Self.int(hex: raw.nonce)
        gasPrice = Self.int(hex: raw.gasPrice)
        gasLimit = Self.int(hex: raw.gas ?? raw.gasLimit)
        maxPriorityFeePerGas = Self.int(hex: raw.maxPriorityFeePerGas)
        maxFeePerGas = Self.int(hex: raw.maxFeePerGas)
        value = raw.value.flatMap { BigUInt(Self.strip(hex: $0), radix: 16) } ?? 0
        data = raw.data.map { Data(hex: $0) } ?? Data()
    }

    var transactionData: TransactionData {
        TransactionData(to: to, value: value, input: data)
    }

    var initialGasPrice: GasPrice? {
        if let maxFeePerGas, let maxPriorityFeePerGas {
            return .eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
        }
        return gasPrice.map { .legacy(gasPrice: $0) }
    }

    private static func int(hex: String?) -> Int? {
        hex.flatMap { Int(strip(hex: $0), radix: 16) }
    }

    private static func strip(hex: String) -> String {
        hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
    }
}

extension WCNEvmTransaction {
    enum ParsingError: Error, Equatable {
        case malformedParams
        case noRecipient
    }
}
