import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct PrivateSendFallbackTests {
    @Test
    func amountIntentMapsToOneUSwapAmountField() {
        #expect(PrivateSendAmountIntent.exactOutput(20).amountSpec == .buy(20))
        #expect(PrivateSendAmountIntent.exactInput(18).amountSpec == .sell(18))
    }

    @Test
    func exactInputOrderUsesExpectedOutputFeeWithoutRefundableBuffer() {
        let order = order(amountIntent: .exactInput(18), depositAmount: 18, amountOut: 17.5)

        #expect(order.privateFee == 0.5)
        #expect(order.refundableBuffer == nil)
    }

    @Test
    func outerAdjustmentStaysSendableWhileInnerAdjustmentDoesNot() {
        let order = order(amountIntent: .exactInput(18), depositAmount: 18, amountOut: 17.5)
        let valid = PrivateSendData(order: order, inner: StubData(canSend: true, amountAdjusted: false), innerHandler: StubHandler())
        let invalid = PrivateSendData(order: order, inner: StubData(canSend: true, amountAdjusted: true), innerHandler: StubHandler())

        #expect(valid.amountAdjusted)
        #expect(valid.canSend)
        #expect(!invalid.canSend)
    }

    @Test
    func adjustedProviderCommitIsCoalescedAndBecomesCurrent() async throws {
        let calls = CallCounter()
        let initial = order(amountIntent: .exactOutput(20), depositAmount: 21, amountOut: 20)
        let adjusted = order(amountIntent: .exactInput(18), depositAmount: 18, amountOut: 17.5)
        let cache = PrivateSendOrderCache(
            initialCommit: { initial },
            adjustedCommit: { _, _ in
                await calls.increment()
                return adjusted
            },
            isFresh: { _ in true }
        )
        let initialEntry = try await cache.current()

        // The two maximums differ by base-unit drift between concurrent estimates; both callers
        // must still share one provider commit.
        async let first = cache.adjusted(from: initialEntry, maximumAmount: 18)
        async let second = cache.adjusted(from: initialEntry, maximumAmount: 17.999995)
        let (firstEntry, secondEntry) = try await (first, second)
        let current = try await cache.current()
        let callCount = await calls.value

        #expect(callCount == 1)
        #expect(firstEntry.generation == secondEntry.generation)
        #expect(current.generation == firstEntry.generation)
        #expect(current.order.amountIntent == .exactInput(18))

        let correctedEntry = try await cache.adjusted(from: firstEntry, maximumAmount: 17.9)
        let correctedCurrent = try await cache.current()
        let correctedCallCount = await calls.value

        #expect(correctedCallCount == 2)
        #expect(correctedEntry.generation != firstEntry.generation)
        #expect(correctedCurrent.generation == correctedEntry.generation)
    }

    @Test
    func supersededSourceEntryThrowsTypedErrorWithoutNewCommit() async throws {
        let calls = CallCounter()
        let initial = order(amountIntent: .exactOutput(20), depositAmount: 21, amountOut: 20)
        let adjusted = order(amountIntent: .exactInput(18), depositAmount: 18, amountOut: 17.5)
        let cache = PrivateSendOrderCache(
            initialCommit: { initial },
            adjustedCommit: { _, _ in
                await calls.increment()
                return adjusted
            },
            isFresh: { _ in true }
        )
        let initialEntry = try await cache.current()
        let adjustedEntry = try await cache.adjusted(from: initialEntry, maximumAmount: 18)
        _ = try await cache.adjusted(from: adjustedEntry, maximumAmount: 17.9)

        do {
            _ = try await cache.adjusted(from: initialEntry, maximumAmount: 18)
            Issue.record("Expected a superseded-order error.")
        } catch let error as PrivateSendError {
            guard case .orderSuperseded = error else {
                Issue.record("Unexpected private send error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let callCount = await calls.value
        #expect(callCount == 2)
    }
}

private extension PrivateSendFallbackTests {
    func order(
        amountIntent: PrivateSendAmountIntent,
        depositAmount: Decimal,
        amountOut: Decimal
    ) -> PrivateSendOrder {
        let token = StubHandler.token
        return PrivateSendOrder(
            request: PrivateSendRequest(token: token, recipient: "recipient", amount: 20),
            amountIntent: amountIntent,
            depositAmount: depositAmount,
            minSellAmount: 17,
            amountOut: amountOut,
            minAmountOut: 17,
            providerId: "provider",
            depositAddress: "deposit",
            attachment: nil,
            providerSwapId: "swap-id",
            refundAddress: "refund",
            estimatedTime: nil,
            committedAt: Date()
        )
    }

    struct StubData: ISendData {
        let canSend: Bool
        let amountAdjusted: Bool

        var feeData: FeeData? { nil }
        var rateCoins: [Coin] { [] }

        func cautions(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] { [] }
        func sections(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] { [] }
    }

    final class StubHandler: ISendHandler {
        static let token = Token(
            coin: Coin(uid: "private-send-test", name: "Test", code: "TST"),
            blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
            type: .eip20(address: "0x0000000000000000000000000000000000000001"),
            decimals: 6
        )

        let baseToken = StubHandler.token

        func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
            StubData(canSend: true, amountAdjusted: false)
        }

        func send(data _: ISendData) async throws {}
    }

    actor CallCounter {
        private(set) var value = 0

        func increment() {
            value += 1
        }
    }
}
