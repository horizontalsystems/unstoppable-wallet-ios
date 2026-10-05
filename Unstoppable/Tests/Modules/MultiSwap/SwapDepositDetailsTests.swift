import Combine
import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct SwapDepositDetailsTests {
    @Test func displaysDepositAndOutputAddressesInTheirOwnNetworks() throws {
        let quote = Self.quote(recipient: "output")
        quote.setDeposit(address: "vault", memo: "=:ETH.ETH:output:123")
        let fields = Self.fields(quote)
        let addresses = fields.compactMap { $0.content as? RecipientField }
        #expect(addresses.count == 2)
        #expect(addresses.contains { $0.value == "output" && $0.blockchainType == .ethereum })
        #expect(addresses.contains { $0.value == "vault" && $0.blockchainType == .bitcoin && $0.copyable })
        let memo = try #require(fields.compactMap { $0.content as? HexField }.first)
        #expect(memo.value == "=:ETH.ETH:output:123")
    }

    @Test func nativeDepositShowsMemoWithoutInventedAddress() {
        let quote = Self.quote()
        quote.setDeposit(address: nil, memo: "=:BTC.BTC:destination")
        let fields = Self.fields(quote)
        #expect(fields.compactMap { $0.content as? RecipientField }.isEmpty)
        #expect(fields.compactMap { $0.content as? HexField }.count == 1)
    }

    @Test func omitsEmptyDetailsAndDoesNotDuplicateUpdates() {
        let quote = Self.quote()
        quote.setDeposit(address: "vault", memo: "memo")
        quote.setDeposit(address: "vault", memo: "memo")
        #expect(Self.fields(quote).count == 2)
        quote.setDeposit(address: "  ", memo: "\n")
        #expect(Self.fields(quote).isEmpty)
    }

    @Test func centrallyPropagatesTransferDetailsEvenWhenBuilderOmitsThem() async throws {
        let execution = USwapMultiSwapApi.Execution.transfer(chain: "bitcoin", depositAddress: "vault", amount: 1, attachment: .text("full memo"), unsignedTx: nil)
        let quote = try await Self.confirmation(execution: execution)
        #expect(quote.depositAddress == "vault")
        #expect(quote.depositMemo == "full memo")
        #expect(quote.toAddress == Self.destination)
    }

    @Test func centrallyPropagatesThorChainDetails() async throws {
        let memo = "=:ETH.ETH:\(Self.destination)/refund:123"
        let quote = try await Self.confirmation(execution: Self.thorExecution(memo: memo))
        #expect(quote.depositAddress == "vault")
        #expect(quote.depositMemo == memo)
    }

    @Test(arguments: ["", "=:ETH.ETH::123", "=:ETH.ETH:0x0000000000000000000000000000000000000000"])
    func rejectsBadMemoBeforeCallingBuilder(_ memo: String) async {
        do {
            _ = try await Self.confirmation(execution: Self.thorExecution(memo: memo), rejectBuild: true)
            Issue.record("Invalid memo reached a final quote")
        } catch is ThorChainSwapMemo.ValidationError {
            // A builder invocation would record an issue and throw BuilderError.called.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func doesNotLabelSignedTransactionAsDeposit() async throws {
        let quote = try await Self.confirmation(execution: .signedTransaction(chain: "ethereum", transactions: [], approval: nil))
        #expect(quote.depositAddress == nil)
        #expect(quote.depositMemo == nil)
    }

    private static let destination = "0x1234567890abcdef1234567890abcdef12345678"

    private static func token(_ type: BlockchainType) -> Token {
        Token(coin: Coin(uid: type.uid, name: "Test", code: "TST"), blockchain: Blockchain(type: type, name: "Test", explorerUrl: nil), type: .native, decimals: 8)
    }

    private static func quote(recipient: String? = nil) -> SwapFinalQuote {
        SwapFinalQuote(expectedBuyAmount: 1, slippage: nil, recipient: recipient, transactionError: nil, toAddress: destination)
    }

    private static func fields(_ quote: SwapFinalQuote) -> [SendField] {
        quote.fields(tokenIn: token(.bitcoin), tokenOut: token(.ethereum), baseToken: token(.bitcoin), currency: Currency(code: "USD", symbol: "$", decimal: 2), tokenInRate: nil, tokenOutRate: nil, baseTokenRate: nil)
    }

    private static func thorExecution(memo: String) -> USwapMultiSwapApi.Execution {
        .thorchainDeposit(chain: "bitcoin", inboundAddress: "vault", memo: memo, delivery: .init(kind: "transfer", router: nil, approval: nil, shieldedMemoAddress: nil, unsignedTx: nil))
    }

    private static func confirmation(execution: USwapMultiSwapApi.Execution, rejectBuild: Bool = false) async throws -> SwapFinalQuote {
        let response = USwapMultiSwapApi.SwapResponse(expectedBuyAmount: 1, minBuyAmount: nil, buyAsset: nil, estimatedTime: nil, execution: execution, uuid: "uuid", approvalSpender: nil)
        let provider = USwapMultiSwapProvider(subProvider: StubSubProvider(response: response), rateQuoteFactory: USwapRateQuoteFactory(builders: []), finalQuoteFactory: USwapFinalQuoteFactory(builders: [StubBuilder(rejectBuild: rejectBuild)]))
        return try await provider.confirmationQuote(multiSwapQuote: MultiSwapQuote(expectedBuyAmount: 1), tokenIn: token(.bitcoin), tokenOut: token(.ethereum), amountIn: 1, slippage: 1, recipient: destination, transactionSettings: nil)
    }

    private struct StubSubProvider: USwapSubProvider {
        let response: USwapMultiSwapApi.SwapResponse
        var info: USwapProviderInfo { .quickEx }
        var syncPublisher: AnyPublisher<Void, Never>? { nil }
        func slippageSupported(tokenIn _: Token, tokenOut _: Token) -> Bool { true }
        func supports(tokenIn _: Token, tokenOut _: Token) -> Bool { true }
        func mevProtectionAllowed(tokenIn _: Token, tokenOut _: Token) -> Bool { false }
        func rate(input _: USwapRateInput) async throws -> USwapRateResult { throw USwapMultiSwapProvider.SwapError.noRoutes }
        func commit(input _: USwapCommitInput) async throws -> USwapCommitResult {
            USwapCommitResult(response: response, refundAddress: nil, destinationAddress: SwapDepositDetailsTests.destination)
        }

        func validateTrustedProvider(tokenIn _: Token, amountIn _: Decimal) async throws -> Bool? { nil }
        func track(swap: Swap) async throws -> Swap { swap }
    }

    private struct StubBuilder: USwapFinalQuoteBuilder {
        let rejectBuild: Bool
        func supports(input _: USwapFinalQuoteFactory.Input) -> Bool { true }
        func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
            if rejectBuild {
                Issue.record("Builder must not run for an invalid swap memo")
                throw BuilderError.called
            }
            return SwapFinalQuote(expectedBuyAmount: input.response.expectedBuyAmount, slippage: input.slippage, recipient: input.recipient, transactionError: nil, toAddress: input.destinationAddress)
        }

        enum BuilderError: Error { case called }
    }
}
