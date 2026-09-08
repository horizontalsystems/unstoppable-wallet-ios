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
        nonce = Self.int(quantity: raw.nonce)
        gasPrice = Self.int(quantity: raw.gasPrice)
        gasLimit = Self.int(quantity: raw.gas ?? raw.gasLimit)
        maxPriorityFeePerGas = Self.int(quantity: raw.maxPriorityFeePerGas)
        maxFeePerGas = Self.int(quantity: raw.maxFeePerGas)
        value = Self.quantity(raw.value) ?? 0
        data = try Self.data(hex: raw.data)
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

    // EVM QUANTITY is unsigned hex; parsing via BigUInt keeps it non-negative (no RLP BigUInt(-1) trap)
    // and overflow-safe, matching Android which parses these fields as hex bytes
    private static func quantity(_ hex: String?) -> BigUInt? {
        hex.flatMap { BigUInt(strip(hex: $0), radix: 16) }
    }

    private static func int(quantity hex: String?) -> Int? {
        quantity(hex).flatMap { Int(exactly: $0) }
    }

    private static func strip(hex: String) -> String {
        hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
    }

    // EVM DATA must be valid hex; a non-failing decode would silently corrupt calldata (odd length,
    // non-hex chars), so reject it instead — Android's hexStringToByteArray throws on odd length too
    private static func data(hex: String?) throws -> Data {
        guard let hex else { return Data() }
        let stripped = strip(hex: hex)
        guard stripped.isEmpty || (stripped.count % 2 == 0 && stripped.allSatisfy(\.isHexDigit)) else {
            throw ParsingError.malformedParams
        }
        return Data(hex: stripped)
    }
}

extension WCNEvmTransaction {
    enum ParsingError: Error, Equatable {
        case malformedParams
        case noRecipient
    }
}
