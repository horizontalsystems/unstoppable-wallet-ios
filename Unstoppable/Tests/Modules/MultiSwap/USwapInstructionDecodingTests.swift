import Foundation
import MarketKit
import ObjectMapper
import Testing
@testable import WalletCore

/// `execution` decoding: the three methods the app follows, attachments, a vault-less MsgDeposit, and
/// an unknown method that must parse as `.unsupported` rather than vanish into "no execution".
struct USwapInstructionDecodingTests {
    private typealias Api = USwapMultiSwapApi

    @Test func signedTransactionDecodes() throws {
        let execution = try Mapper<Api.ExecutionResponse>().map(JSON: [
            "method": "signed_transaction",
            "chain": "ethereum",
            "transactions": [["kind": "evm", "json": ["to": "0xrouter", "data": "0x00"]]],
            "approval": ["spender": "0xspender"],
        ]).execution

        guard case let .signedTransaction(chain, transactions, approval) = execution else {
            Issue.record("expected signedTransaction, got \(execution)")
            return
        }

        #expect(chain == "ethereum")
        #expect(transactions.first?.kind == "evm")
        #expect(approval?.spender == "0xspender")
        #expect(execution.method == "signed_transaction")
        #expect(!execution.isUnsupported)
    }

    @Test func transferDecodesWithTextAttachment() throws {
        let execution = try Mapper<Api.ExecutionResponse>().map(JSON: [
            "method": "transfer",
            "chain": "bitcoin",
            "depositAddress": "bc1qdeposit",
            "amount": "0.01",
            "attachment": ["type": "text", "value": "order-123"],
        ]).execution

        #expect(execution.isTransfer)
        #expect(execution.depositAddress == "bc1qdeposit")
        #expect(execution.depositInstruction()?.attachment == .text("order-123"))
    }

    @Test func transferDecodesDestinationTagAttachment() throws {
        let execution = try Mapper<Api.ExecutionResponse>().map(JSON: [
            "method": "transfer",
            "chain": "ripple",
            "depositAddress": "rDeposit",
            "attachment": ["type": "destination_tag", "value": 12345],
        ]).execution

        #expect(execution.depositInstruction()?.attachment == .destinationTag("12345"))
    }

    @Test func thorchainDepositDecodes() throws {
        let execution = try Mapper<Api.ExecutionResponse>().map(JSON: [
            "method": "thorchain_deposit",
            "chain": "bitcoin",
            "inboundAddress": "bc1qvault",
            "memo": "=:ETH.ETH:0xdest:123",
            "delivery": ["kind": "transfer"],
        ]).execution

        #expect(execution.depositAddress == "bc1qvault")
        #expect(execution.depositInstruction()?.attachment == .text("=:ETH.ETH:0xdest:123"))
        #expect(execution.method == "thorchain_deposit")
    }

    /// A settlement-native sell names no vault: a MsgDeposit with nothing to display or send to.
    @Test func thorchainDepositWithoutVaultHasNoDepositInstruction() throws {
        let execution = try Mapper<Api.ExecutionResponse>().map(JSON: [
            "method": "thorchain_deposit",
            "chain": "thorchain",
            "memo": "=:BTC.BTC:bc1qdest",
            "delivery": ["kind": "cosmos_memo"],
        ]).execution

        #expect(execution.depositAddress == nil)
        #expect(execution.depositInstruction() == nil)
    }

    @Test func unknownMethodDecodesAsUnsupported() throws {
        let execution = try Mapper<Api.ExecutionResponse>().map(JSON: [
            "method": "stellar_broker",
            "chain": "stellar",
            "session": ["url": "wss://broker"],
        ]).execution

        #expect(execution.isUnsupported)
        #expect(execution.method == "stellar_broker")
        #expect(execution.chain == "stellar")
        #expect(!execution.isTransfer)
        #expect(execution.primarySignable == nil)
        #expect(execution.depositInstruction() == nil)
    }

    /// The preview mapping must keep an unsupported execution rather than reading it as absent.
    @Test func previewKeepsUnsupportedExecution() throws {
        let response = try Mapper<Api.SwapResponseMapping>().map(JSON: [
            "expectedBuyAmount": "1",
            "previewToken": "t",
            "execution": ["method": "teleport", "chain": "ethereum"],
        ]).response

        #expect(response.execution?.isUnsupported == true)
    }

    // MARK: - USwapInstructionSupport

    @Test func supportTableMirrorsTheBuilders() {
        #expect(USwapInstructionSupport.supports(method: "signed_transaction", blockchainType: .ethereum))
        #expect(USwapInstructionSupport.supports(method: "thorchain_deposit", blockchainType: .ethereum))
        #expect(USwapInstructionSupport.supports(method: "transfer", blockchainType: .bitcoin))
        #expect(USwapInstructionSupport.supports(method: "thorchain_deposit", blockchainType: .bitcoin))
        #expect(!USwapInstructionSupport.supports(method: "signed_transaction", blockchainType: .bitcoin))
        #expect(USwapInstructionSupport.supports(method: "signed_transaction", blockchainType: .solana))
        #expect(!USwapInstructionSupport.supports(method: "thorchain_deposit", blockchainType: .solana))
        #expect(USwapInstructionSupport.supports(method: "transfer", blockchainType: .monero))
        #expect(!USwapInstructionSupport.supports(method: "signed_transaction", blockchainType: .monero))
        #expect(USwapInstructionSupport.supports(method: "thorchain_deposit", blockchainType: .thorChain))
        #expect(!USwapInstructionSupport.supports(method: "transfer", blockchainType: .thorChain))
        #expect(!USwapInstructionSupport.supports(method: "stellar_broker", blockchainType: .stellar))
        #expect(USwapInstructionSupport.methods(blockchainType: .unsupported(uid: "x")).isEmpty)
    }

    // MARK: - USwapRouteFilter

    @Test func routeFilterDropsVaultRoutesWithoutMemoAndStellarBroker() {
        let executionTypes = [
            "THORCHAIN": "thorchain_deposit",
            "STELLARBROKER": "stellar_broker",
            "EXOLIX": "transfer",
            "JUPITER": "signed_transaction",
        ]
        let routes = ["THORCHAIN", "STELLARBROKER", "EXOLIX", "JUPITER", "NEWCOMER"].map(Self.route)

        let fromSolana = USwapRouteFilter.filter(routes, tokenIn: Self.token(.solana)) { executionTypes[$0] }
        #expect(fromSolana.map(\.providerId) == ["EXOLIX", "JUPITER", "NEWCOMER"])

        let fromBitcoin = USwapRouteFilter.filter(routes, tokenIn: Self.token(.bitcoin)) { executionTypes[$0] }
        #expect(fromBitcoin.map(\.providerId) == ["THORCHAIN", "EXOLIX", "JUPITER", "NEWCOMER"])

        let fromEthereum = USwapRouteFilter.filter(routes, tokenIn: Self.token(.ethereum)) { executionTypes[$0] }
        #expect(fromEthereum.map(\.providerId) == ["THORCHAIN", "EXOLIX", "JUPITER", "NEWCOMER"])
    }

    @Test func routeFilterDropsRoutesNamingNoProvider() {
        let routes = ["EXOLIX", ""].map(Self.route)

        let filtered = USwapRouteFilter.filter(routes, tokenIn: Self.token(.bitcoin)) { _ in "transfer" }
        #expect(filtered.map(\.providerId) == ["EXOLIX"])
    }

    @Test func vaultDepositSupportFollowsTheMemoChannel() {
        #expect(USwapRouteFilter.supportsVaultDeposit(blockchainType: .bitcoin))
        #expect(USwapRouteFilter.supportsVaultDeposit(blockchainType: .ethereum))
        #expect(USwapRouteFilter.supportsVaultDeposit(blockchainType: .zcash))
        #expect(USwapRouteFilter.supportsVaultDeposit(blockchainType: .thorChain))
        #expect(!USwapRouteFilter.supportsVaultDeposit(blockchainType: .solana))
        #expect(!USwapRouteFilter.supportsVaultDeposit(blockchainType: .tron))
        #expect(!USwapRouteFilter.supportsVaultDeposit(blockchainType: .xrp))
    }

    private static func route(_ providerId: String) -> Api.RateQuote {
        Api.RateQuote(expectedBuyAmount: 1, minBuyAmount: nil, buyAsset: nil, estimatedTime: nil, approvalSpender: nil, providerId: providerId)
    }

    private static func token(_ blockchainType: BlockchainType) -> Token {
        Token(
            coin: Coin(uid: blockchainType.uid, name: blockchainType.uid, code: blockchainType.uid.uppercased()),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: .native,
            decimals: 8
        )
    }
}
