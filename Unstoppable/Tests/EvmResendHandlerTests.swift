import BigInt
import EvmKit
import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct EvmResendHandlerTests {
    private let baseToken = Token(
        coin: Coin(uid: "ethereum", name: "Ethereum", code: "ETH"),
        blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
        type: .native, decimals: 18
    )

    private func address(_ digit: String = "1") throws -> EvmKit.Address {
        try EvmKit.Address(hex: "0x" + String(repeating: digit, count: 40))
    }

    private func transaction(from: EvmKit.Address? = nil, nonce: Int? = 7, blockNumber: Int? = nil, replacedWith: Data? = nil, isFailed: Bool = false) throws -> EvmKit.Transaction {
        try EvmKit.Transaction(
            hash: Data(repeating: 1, count: 32), timestamp: 0, isFailed: isFailed,
            blockNumber: blockNumber, from: from ?? address(), to: address("2"),
            value: 123, input: Data([0xAB, 0xCD]), nonce: nonce,
            gasLimit: 54321, replacedWith: replacedWith
        )
    }

    private func prepare(_ transaction: EvmKit.Transaction, blockchainType: BlockchainType = .ethereum, isProtected: Bool = false, type: ResendTransactionType = .speedUp) throws -> EvmReplacementData {
        try EvmResendHandler.prepare(transaction: transaction, blockchainType: blockchainType, receiveAddress: address(), isProtected: isProtected, type: type)
    }

    private func kit() throws -> EvmKit.Kit {
        try EvmKit.Kit.instance(
            address: address(), chain: .ethereum, rpcSource: .http(urls: [], auth: nil),
            transactionSource: .ethereumEtherscan(apiKeys: []), walletId: "resend-test-\(UUID().uuidString)"
        )
    }

    @Test func speedUpPreviewKeepsGasValueAndNonceWithoutSendAll() async throws {
        let kit = try kit()
        let original = try transaction()
        kit.transactionManager.handle(transactions: [original])
        let wrapper = EvmKitWrapper(blockchainType: .ethereum, evmKit: kit, merkleTransactionAdapter: nil, signer: nil)
        let handler = EvmResendHandler(baseToken: baseToken, evmKitWrapper: wrapper, transaction: original, type: .speedUp)
        let prices = GasPriceData(recommended: .legacy(gasPrice: 10), userDefined: .legacy(gasPrice: 15))

        let sendData = try await handler.sendData(transactionSettings: .evm(gasPriceData: prices, nonce: 999))
        let data = try #require(sendData as? EvmResendData)

        #expect(data.nonce == 7)
        #expect(data.transactionData?.value == 123)
        #expect(data.evmFeeData?.gasLimit == 54321)
        #expect(data.evmFeeData?.surchargedGasLimit == 54321)
        #expect(data.gasPrice == prices.userDefined)
        #expect(!data.canSend) // The unsynced fixture has no balance; the amount must not be reduced.
        #expect(handler.expirationDuration == nil)
        #expect(handler.autoRefreshEnabled)
    }

    @Test func sendRejectsTransactionConfirmedAfterPreview() async throws {
        let kit = try kit()
        let original = try transaction()
        kit.transactionManager.handle(transactions: [original])
        let wrapper = EvmKitWrapper(blockchainType: .ethereum, evmKit: kit, merkleTransactionAdapter: nil, signer: nil)
        let handler = EvmResendHandler(baseToken: baseToken, evmKitWrapper: wrapper, transaction: original, type: .speedUp)
        let replacement = try prepare(original)
        let data = try EvmSendData(
            decoration: EvmDecoration(type: .outgoingEvm(to: address("2"), value: 1), customSendButtonTitle: nil),
            transactionData: replacement.transactionData, transactionError: nil,
            gasPrice: .legacy(gasPrice: 10), evmFeeData: EvmFeeData(gasLimit: 54321, surchargedGasLimit: 54321), nonce: 7
        )
        kit.transactionManager.handle(transactions: [try transaction(blockNumber: 123)])

        await #expect(throws: EvmReplacementData.ValidationError.alreadyInBlock) {
            try await handler.send(data: data)
        }
    }

    @Test @MainActor func replacementNonceCannotBeEditedOrReset() throws {
        let service = try #require(EvmTransactionService(
            blockchainType: .ethereum, evmKit: kit(), initialTransactionSettings: .evm(gasPrice: nil, nonce: 999),
            previousTransaction: transaction()
        ))

        #expect(!service.nonceEditable)
        #expect(!service.modified)
        service.set(nonce: 123)
        #expect(service.currentNonce == 7)
        service.set(nonce: nil)
        #expect(service.currentNonce == 7)
        service.set(gasPrice: .legacy(gasPrice: 100))
        #expect(service.modified)
        #expect(service.currentGasPrice == .legacy(gasPrice: 100))
    }

    @Test @MainActor func ordinaryNonceRemainsEditable() throws {
        let service = try #require(EvmTransactionService(blockchainType: .ethereum, evmKit: kit(), initialTransactionSettings: nil))

        #expect(service.nonceEditable)
        service.set(nonce: 123)
        #expect(service.currentNonce == 123)
        #expect(service.modified)
        service.set(nonce: nil)
        #expect(service.nonce == nil)
        #expect(!service.modified)
    }

    @Test(arguments: [BlockchainType.ethereum, .binanceSmartChain, .polygon], [ResendTransactionType.speedUp, .cancel])
    func ownPendingTransactionKeepsReplacementPayload(blockchainType: BlockchainType, type: ResendTransactionType) throws {
        let original = try transaction()
        let replacement = try prepare(original, blockchainType: blockchainType, type: type)

        switch type {
        case .speedUp:
            #expect(replacement.transactionData.to == original.to)
            #expect(replacement.transactionData.value == 123)
            #expect(replacement.transactionData.input == Data([0xAB, 0xCD]))
            #expect(replacement.predefinedGasLimit == 54321)
        case .cancel:
            #expect(replacement.transactionData.to == (try address()))
            #expect(replacement.transactionData.value == 0)
            #expect(replacement.transactionData.input.isEmpty)
            #expect(replacement.predefinedGasLimit == nil)
        }
    }

    @Test(arguments: [BlockchainType.optimism, .arbitrumOne, .base])
    func unsupportedNetworkIsRejected(blockchainType: BlockchainType) throws {
        let original = try transaction()

        #expect(throws: EvmResendHandler.ValidationError.notAllowed) {
            try prepare(original, blockchainType: blockchainType)
        }
    }

    @Test func protectedTransactionIsRejected() throws {
        let original = try transaction()

        #expect(throws: EvmResendHandler.ValidationError.notAllowed) {
            try prepare(original, isProtected: true)
        }
    }

    @Test func confirmedTransactionIsRejected() throws {
        let original = try transaction(blockNumber: 123)

        #expect(throws: EvmReplacementData.ValidationError.alreadyInBlock) {
            try prepare(original)
        }
    }

    @Test func replacedTransactionIsRejected() throws {
        let original = try transaction(replacedWith: Data(repeating: 2, count: 32))

        #expect(throws: EvmResendHandler.ValidationError.alreadyReplaced) {
            try prepare(original)
        }
    }

    @Test func failedTransactionIsRejected() throws {
        let original = try transaction(isFailed: true)

        #expect(throws: EvmResendHandler.ValidationError.notAllowed) {
            try prepare(original)
        }
    }

    @Test func anotherWalletTransactionIsRejected() throws {
        let original = try transaction(from: address("3"))

        #expect(throws: EvmReplacementData.ValidationError.wrongTransaction) {
            try prepare(original)
        }
    }

    @Test func missingNonceIsRejected() throws {
        let original = try transaction(nonce: nil)

        #expect(throws: EvmReplacementData.ValidationError.wrongTransaction) {
            try prepare(original)
        }
    }
}
