import BigInt
import EvmKit
import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNEvmTransactionTests {
    // params[0] exactly as react-app.walletconnect.com sent it during the 2026-09-02 spike
    private let spikeParams: [[String: String]] = [[
        "from": "0x3f4E9c3Ac73a4cff7540293c24a3D055E03fd78d",
        "to": "0x3f4E9c3Ac73a4cff7540293c24a3D055E03fd78d",
        "data": "0x",
        "gasLimit": "0x5208",
        "gasPrice": "0x06bb7166",
        "nonce": "0x0146",
        "value": "0x00",
    ]]

    @Test func parsesSpikeParams() throws {
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: spikeParams))

        #expect(transaction.from.eip55 == WCNTestFixtures.address)
        #expect(transaction.to.eip55 == WCNTestFixtures.address)
        #expect(transaction.gasLimit == 21000)
        #expect(transaction.gasPrice == 0x06BB_7166)
        #expect(transaction.nonce == 326)
        #expect(transaction.value == 0)
        #expect(transaction.data.isEmpty)
        #expect(transaction.initialGasPrice == .legacy(gasPrice: 0x06BB_7166))
    }

    @Test func gasTakesPrecedenceOverLegacyGasLimit() throws {
        var params = spikeParams
        params[0]["gas"] = "0x7530"
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        #expect(transaction.gasLimit == 30000)
    }

    @Test func eip1559FieldsProduceEip1559GasPrice() throws {
        var params = spikeParams
        params[0]["gasPrice"] = nil
        params[0]["maxFeePerGas"] = "0x3b9aca00"
        params[0]["maxPriorityFeePerGas"] = "0x3b9aca0"
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        #expect(transaction.initialGasPrice == .eip1559(maxFeePerGas: 1_000_000_000, maxPriorityFeePerGas: 62_500_000))
    }

    @Test func missingFeeFieldsLeaveGasPriceNil() throws {
        var params = spikeParams
        params[0]["gasPrice"] = nil
        params[0]["nonce"] = nil
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        #expect(transaction.initialGasPrice == nil)
        #expect(transaction.nonce == nil)
    }

    @Test func valueAndDataDecode() throws {
        var params = spikeParams
        params[0]["value"] = "0xde0b6b3a7640000"
        params[0]["data"] = "0xa9059cbb"
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        #expect(transaction.value == BigUInt(1_000_000_000_000_000_000))
        #expect(transaction.data == Data([0xA9, 0x05, 0x9C, 0xBB]))
        #expect(transaction.transactionData.input == transaction.data)
        #expect(transaction.transactionData.value == transaction.value)
    }

    @Test func missingRecipientIsRejected() {
        var params = spikeParams
        params[0]["to"] = nil
        #expect(throws: WCNEvmTransaction.ParsingError.noRecipient) {
            try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        }
    }

    @Test func malformedParamsAreRejected() {
        #expect(throws: WCNEvmTransaction.ParsingError.malformedParams) {
            try WCNEvmTransaction.parse(params: AnyCodable(any: ["not", "a", "transaction"]))
        }
        #expect(throws: WCNEvmTransaction.ParsingError.malformedParams) {
            try WCNEvmTransaction.parse(params: AnyCodable(any: [[String: String]]()))
        }
    }

    @Test func negativeQuantityIsDroppedNotTrapped() throws {
        var params = spikeParams
        params[0]["nonce"] = "-1"
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        #expect(transaction.nonce == nil) // BigUInt rejects the sign, so no RLP BigUInt(-1) trap downstream
    }

    @Test func overflowingIntQuantityIsDroppedNotTrapped() throws {
        var params = spikeParams
        params[0]["gasPrice"] = "0x" + String(repeating: "f", count: 40) // far beyond Int.max
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        #expect(transaction.gasPrice == nil) // Int(exactly:) returns nil instead of trapping
    }

    @Test func overflowingValueStaysUnboundedBigUInt() throws {
        var params = spikeParams
        params[0]["value"] = "0x" + String(repeating: "f", count: 40)
        let transaction = try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        #expect(transaction.value > BigUInt(UInt64.max))
    }

    @Test func oddLengthCalldataIsRejected() {
        var params = spikeParams
        params[0]["data"] = "0xabc"
        #expect(throws: WCNEvmTransaction.ParsingError.malformedParams) {
            try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        }
    }

    @Test func nonHexCalldataIsRejected() {
        var params = spikeParams
        params[0]["data"] = "0xzzzz"
        #expect(throws: WCNEvmTransaction.ParsingError.malformedParams) {
            try WCNEvmTransaction.parse(params: AnyCodable(any: params))
        }
    }
}
