import BigInt
import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import MoneroKit
import ObjectMapper
import Testing
import TronKit
@testable import Unstoppable
@testable import WalletCore

// build-argument equivalence oracle: executable(tokenIn:) must repackage
// exactly the fields MultiSwapSendHandler.send reads from each quote today
struct SwapExecutableTests {
    private static func token(blockchainType: BlockchainType = .ethereum) -> Token {
        Token(
            coin: Coin(uid: "test-coin", name: "Test", code: "TST"),
            blockchain: Blockchain(type: blockchainType, name: "Test", explorerUrl: nil),
            type: .native,
            decimals: 8
        )
    }

    @Test func evmQuoteMapsAllSendArguments() throws {
        let transactionData = try TransactionData(
            to: EvmKit.Address(hex: "0x1234567890123456789012345678901234567890"),
            value: BigUInt(100),
            input: Data([0x01, 0x02])
        )
        let gasPrice = GasPrice.legacy(gasPrice: 1_000_000_000)
        let quote = EvmSwapFinalQuote(
            expectedBuyAmount: 1,
            transactionData: transactionData,
            slippage: nil,
            recipient: nil,
            gasPrice: gasPrice,
            evmFeeData: EvmFeeData(gasLimit: 100_000, surchargedGasLimit: 110_000),
            nonce: 7,
            mevProtectionAllowed: true,
            toAddress: "to"
        )

        let token = Self.token()
        let executable = try #require(quote.executable(tokenIn: token) as? EvmExecutable)

        #expect(executable.token == token)
        #expect(executable.transactionData == transactionData)
        #expect(executable.gasPrice == gasPrice)
        #expect(executable.gasLimit == 110_000) // surchargedGasLimit, not gasLimit
        #expect(executable.nonce == 7)
        #expect(executable.mevProtectionAllowed == true)
        #expect(executable.approval == nil)
    }

    @Test func evmQuotePreservesNilOptionalsAndMevDefaultOff() throws {
        let quote = EvmSwapFinalQuote(
            expectedBuyAmount: 1,
            transactionData: nil,
            slippage: nil,
            recipient: nil,
            gasPrice: nil,
            evmFeeData: nil,
            nonce: nil,
            toAddress: "to"
        )

        let executable = try #require(quote.executable(tokenIn: Self.token()) as? EvmExecutable)

        #expect(executable.transactionData == nil)
        #expect(executable.gasPrice == nil)
        #expect(executable.gasLimit == nil)
        #expect(executable.nonce == nil)
        #expect(executable.mevProtectionAllowed == false)
    }

    @Test func evmQuoteCarriesApprovalIntent() throws {
        let approval = try SwapApproval(
            spender: EvmKit.Address(hex: "0x1111111111111111111111111111111111111111"),
            token: EvmKit.Address(hex: "0x2222222222222222222222222222222222222222"),
            amount: BigUInt(500)
        )
        let quote = EvmSwapFinalQuote(
            expectedBuyAmount: 1,
            transactionData: nil,
            slippage: nil,
            recipient: nil,
            gasPrice: nil,
            evmFeeData: nil,
            nonce: nil,
            approval: approval,
            toAddress: "to"
        )

        let executable = try #require(quote.executable(tokenIn: Self.token()) as? EvmExecutable)

        #expect(executable.approval?.spender == approval.spender)
        #expect(executable.approval?.token == approval.token)
        #expect(executable.approval?.amount == approval.amount)
    }

    @Test func utxoQuoteCarriesTokenAndSendParameters() throws {
        let sendParameters = SendParameters(address: "addr", value: 1000, feeRate: 10, memo: "m")
        let quote = UtxoSwapFinalQuote(
            expectedBuyAmount: 1,
            sendParameters: sendParameters,
            slippage: 1,
            recipient: nil,
            transactionError: nil,
            fee: 0.1,
            toAddress: "to"
        )
        let token = Self.token(blockchainType: .bitcoin)

        let executable = try #require(quote.executable(tokenIn: token) as? UtxoExecutable)

        #expect(executable.token == token)
        #expect(executable.sendParameters === sendParameters)
    }

    @Test func zcashQuoteCarriesTokenAndProposal() throws {
        // Proposal wraps an FFI type and is not constructible in tests; nil verifies the pass-through shape
        let quote = ZcashSwapFinalQuote(
            expectedBuyAmount: 1,
            proposal: nil,
            slippage: 1,
            recipient: nil,
            transactionError: nil,
            fee: 0.001,
            toAddress: "to"
        )
        let token = Self.token(blockchainType: .zcash)

        let executable = try #require(quote.executable(tokenIn: token) as? ZcashExecutable)

        #expect(executable.token == token)
        #expect(executable.proposal == nil)
    }

    @Test func tonQuoteCarriesTransactionParam() throws {
        let json = """
        {"messages": [], "valid_until": 123, "from": "0:0000000000000000000000000000000000000000000000000000000000000000", "network": "-239"}
        """
        let param = try JSONDecoder().decode(SendTransactionParam.self, from: Data(json.utf8))
        let quote = TonSwapFinalQuote(
            amountIn: 1,
            expectedAmountOut: 2,
            recipient: nil,
            slippage: 1,
            transactionParam: param,
            fee: 0.01,
            transactionError: nil,
            toAddress: "to"
        )

        let executable = try #require(quote.executable(tokenIn: Self.token(blockchainType: .ton)) as? TonExecutable)

        #expect(executable.transactionParam.validUntil == 123)
        #expect(executable.transactionParam.messages.isEmpty)
    }

    @Test func tronQuoteCarriesCreatedTransactionAndNilTransferIntent() throws {
        let created = try Mapper<CreatedTransactionResponse>().map(JSON: [
            "visible": false,
            "txID": "aabbcc",
            "raw_data": [
                "ref_block_bytes": "0000",
                "ref_block_hash": "1122",
                "expiration": 1,
                "fee_limit": 1000,
                "timestamp": 2,
            ],
            "raw_data_hex": "deadbeef",
        ])
        let quote = TronSwapFinalQuote(
            amountIn: 1,
            expectedAmountOut: 2,
            recipient: nil,
            slippage: nil,
            createdTransaction: created,
            fees: [],
            transactionError: nil,
            toAddress: "to"
        )

        let executable = try #require(quote.executable(tokenIn: Self.token(blockchainType: .tron)) as? TronExecutable)

        let executableCreated = try #require(executable.created)

        #expect(executableCreated.txID == created.txID)
        #expect(executableCreated.rawDataHex == created.rawDataHex)
        #expect(executable.transferIntent == nil)
    }

    @Test func tronQuoteCarriesTransferIntent() throws {
        let created = try Mapper<CreatedTransactionResponse>().map(JSON: [
            "visible": false,
            "txID": "aabbcc",
            "raw_data": [
                "ref_block_bytes": "0000",
                "ref_block_hash": "1122",
                "expiration": 1,
                "fee_limit": 1000,
                "timestamp": 2,
            ],
            "raw_data_hex": "deadbeef",
        ])
        let intent = try TronTransferIntent(
            token: TronKit.Address(address: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"),
            receiver: TronKit.Address(address: "TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9"),
            value: BigUInt(1000)
        )
        let quote = TronSwapFinalQuote(
            amountIn: 1,
            expectedAmountOut: 2,
            recipient: nil,
            slippage: nil,
            createdTransaction: created,
            transferIntent: intent,
            fees: [],
            transactionError: nil,
            toAddress: "to"
        )

        let executable = try #require(quote.executable(tokenIn: Self.token(blockchainType: .tron)) as? TronExecutable)

        #expect(executable.transferIntent?.token == intent.token)
        #expect(executable.transferIntent?.receiver == intent.receiver)
        #expect(executable.transferIntent?.value == intent.value)
    }

    @Test func stellarQuoteCarriesTokenInAndTransactionData() throws {
        // the switch passes the handler's tokenIn to StellarSendHelper.send, NOT the quote's stored token
        let storedToken = Self.token(blockchainType: .stellar)
        let tokenIn = Token(
            coin: Coin(uid: "other-coin", name: "Other", code: "OTH"),
            blockchain: Blockchain(type: .stellar, name: "Stellar", explorerUrl: nil),
            type: .native,
            decimals: 7
        )
        let quote = StellarSwapFinalQuote(
            amountIn: 1,
            expectedAmountOut: 2,
            recipient: nil,
            slippage: nil,
            transactionData: .envelope("xdr-envelope"),
            token: storedToken,
            fee: 0.1,
            transactionError: nil,
            toAddress: "to"
        )

        let executable = try #require(quote.executable(tokenIn: tokenIn) as? StellarExecutable)

        #expect(executable.token == tokenIn)
        guard case let .envelope(envelope) = executable.transactionData else {
            Issue.record("expected .envelope")
            return
        }
        #expect(envelope == "xdr-envelope")
    }

    @Test func moneroQuoteMapsAllSendArguments() throws {
        let quote = MoneroSwapFinalQuote(
            amountIn: 1,
            expectedAmountOut: 2,
            recipient: nil,
            slippage: nil,
            amount: .value(3),
            address: "monero-addr",
            memo: "memo",
            token: Self.token(blockchainType: .monero),
            priority: .low,
            fee: 0.1,
            transactionError: nil,
            toAddress: "to"
        )
        let token = Self.token(blockchainType: .monero)

        let executable = try #require(quote.executable(tokenIn: token) as? MoneroExecutable)

        #expect(executable.token == token)
        #expect(executable.address == "monero-addr")
        #expect(executable.amount.value == 3)
        #expect(executable.priority == .low)
        #expect(executable.memo == "memo")
    }

    @Test func zanoQuoteMapsAllSendArguments() throws {
        let quote = ZanoSwapFinalQuote(
            expectedAmountOut: 2,
            recipient: nil,
            slippage: nil,
            amount: .value(4),
            address: "zano-addr",
            memo: "memo",
            fee: 0.1,
            transactionError: nil,
            toAddress: "to"
        )
        let token = Self.token(blockchainType: .zano)

        let executable = try #require(quote.executable(tokenIn: token) as? ZanoExecutable)

        #expect(executable.token == token)
        #expect(executable.address == "zano-addr")
        #expect(executable.amount.value == 4)
        #expect(executable.memo == "memo")
    }

    @Test func solanaQuoteCarriesTokenAndRawTransaction() throws {
        let rawTransaction = Data([0xAA, 0xBB])
        let quote = SolanaSwapFinalQuote(
            rawTransaction: rawTransaction,
            expectedAmountOut: 2,
            recipient: nil,
            slippage: nil,
            fee: 0.1,
            transactionError: nil,
            toAddress: "to",
            depositAddress: nil,
            providerSwapId: nil
        )
        let token = Self.token(blockchainType: .solana)

        let executable = try #require(quote.executable(tokenIn: token) as? SolanaExecutable)

        #expect(executable.token == token)
        #expect(executable.rawTransaction == rawTransaction)
    }

    @Test func baseQuoteReturnsUnsupportedExecutable() {
        let quote = SwapFinalQuote(
            expectedBuyAmount: 1,
            slippage: nil,
            recipient: nil,
            transactionError: nil,
            toAddress: "to"
        )

        let executable = quote.executable(tokenIn: Self.token())

        #expect(executable is UnsupportedExecutable)
    }
}
