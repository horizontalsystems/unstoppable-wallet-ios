import BigInt
import EvmKit
import Foundation
import Testing
@testable import WalletCore

struct EvmReplacementDataTests {
    private func receiveAddress() throws -> EvmKit.Address {
        try EvmKit.Address(hex: "0x1111111111111111111111111111111111111111")
    }

    private func transaction(blockNumber: Int? = nil, gasLimit: Int? = 54321, missingField: String? = nil) throws -> EvmKit.Transaction {
        try EvmKit.Transaction(
            hash: Data(repeating: 1, count: 32), timestamp: 0, isFailed: false, blockNumber: blockNumber,
            to: missingField == "to" ? nil : EvmKit.Address(hex: "0x2222222222222222222222222222222222222222"),
            value: missingField == "value" ? nil : 123,
            input: missingField == "input" ? nil : Data([0xAB, 0xCD]), nonce: 7, gasLimit: gasLimit
        )
    }

    @Test func speedUpPreservesPayloadAndExactGasLimit() throws {
        let original = try transaction()
        let replacement = try EvmReplacementData(transaction: original, receiveAddress: receiveAddress(), type: .speedUp)

        #expect(replacement.transactionData.to == original.to)
        #expect(replacement.transactionData.value == 123)
        #expect(replacement.transactionData.input == Data([0xAB, 0xCD]))
        #expect(replacement.predefinedGasLimit == 54321)
    }

    @Test func cancelSendsZeroToSelfWithoutCalldataOrPredefinedGasLimit() throws {
        let receiveAddress = try receiveAddress()
        let replacement = try EvmReplacementData(transaction: transaction(), receiveAddress: receiveAddress, type: .cancel)

        #expect(replacement.transactionData.to == receiveAddress)
        #expect(replacement.transactionData.value == 0)
        #expect(replacement.transactionData.input.isEmpty)
        #expect(replacement.predefinedGasLimit == nil)
    }

    @Test func speedUpAllowsMissingGasLimit() throws {
        let original = try transaction(gasLimit: nil)

        let replacement = try EvmReplacementData(transaction: original, receiveAddress: receiveAddress(), type: .speedUp)

        #expect(replacement.predefinedGasLimit == nil)
    }

    @Test(arguments: [ResendTransactionType.speedUp, .cancel])
    func confirmedTransactionIsRejected(type: ResendTransactionType) throws {
        let original = try transaction(blockNumber: 123)
        let receiveAddress = try receiveAddress()

        #expect(throws: EvmReplacementData.ValidationError.alreadyInBlock) {
            try EvmReplacementData(transaction: original, receiveAddress: receiveAddress, type: type)
        }
    }

    @Test(arguments: [ResendTransactionType.speedUp, .cancel], ["to", "value", "input"])
    func incompleteTransactionIsRejected(type: ResendTransactionType, missingField: String) throws {
        let original = try transaction(missingField: missingField)
        let receiveAddress = try receiveAddress()

        #expect(throws: EvmReplacementData.ValidationError.wrongTransaction) {
            try EvmReplacementData(transaction: original, receiveAddress: receiveAddress, type: type)
        }
    }
}
