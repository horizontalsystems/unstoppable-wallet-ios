import BigInt
import EvmKit
import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

// Step-2 type-selection: DirectPrepared keeps quote-based fee/canSend,
// an IPreparedDisplay prepared overrides them
struct SwapSendDataTests {
    private static func token(uid: String = "test-coin") -> Token {
        Token(
            coin: Coin(uid: uid, name: "Test", code: "TST"),
            blockchain: Blockchain(type: .ethereum, name: "Test", explorerUrl: nil),
            type: .native,
            decimals: 8
        )
    }

    private static func evmQuote(canSwap: Bool = true) -> EvmSwapFinalQuote {
        EvmSwapFinalQuote(
            expectedBuyAmount: 1,
            transactionData: canSwap ? try? TransactionData(
                to: EvmKit.Address(hex: "0x1234567890123456789012345678901234567890"),
                value: 100,
                input: Data()
            ) : nil,
            slippage: nil,
            recipient: nil,
            gasPrice: canSwap ? .legacy(gasPrice: 1_000_000_000) : nil,
            evmFeeData: canSwap ? EvmFeeData(gasLimit: 100_000, surchargedGasLimit: 110_000) : nil,
            nonce: nil,
            toAddress: "to"
        )
    }

    private static func sendData(quote: SwapFinalQuote, prepared: IPrepared) -> MultiSwapSendHandler.SendData {
        MultiSwapSendHandler.SendData(
            tokenIn: token(uid: "in"),
            tokenOut: token(uid: "out"),
            amountIn: 1,
            quote: quote,
            prepared: prepared,
            broadcaster: StubBroadcaster(),
            otherSections: []
        )
    }

    @Test func directPreparedKeepsQuoteBehaviour() {
        let quote = Self.evmQuote()
        let data = Self.sendData(quote: quote, prepared: DirectPrepared(executable: StubExecutable()))

        #expect(data.feeData != nil)
        #expect(data.canSend == quote.canSwap)
        #expect(data.rateCoins.map(\.uid) == ["in", "out"])
    }

    @Test func directPreparedReflectsQuoteCanSwapFalse() {
        let data = Self.sendData(quote: Self.evmQuote(canSwap: false), prepared: DirectPrepared(executable: StubExecutable()))

        #expect(data.canSend == false)
        #expect(data.feeData == nil)
    }

    @Test func displayPreparedOverridesFeeAndCanSend() {
        let extraCoin = Coin(uid: "fee-coin", name: "Fee", code: "FEE")
        let prepared = StubDisplayPrepared(canSend: true, extraRateCoins: [extraCoin])
        // quote CANNOT swap (nil evmFeeData) and carries no feeData, but display prepared rules
        let data = Self.sendData(quote: Self.evmQuote(canSwap: false), prepared: prepared)

        #expect(data.canSend == true)
        #expect(data.feeData == nil)
        #expect(data.rateCoins.map(\.uid) == ["in", "out", "fee-coin"])
    }

    @Test func displayPreparedSuppressesQuoteFeeData() {
        let prepared = StubDisplayPrepared(canSend: false, extraRateCoins: [])
        // quote CAN swap and has feeData — display prepared must suppress it (no "Edit Fee")
        let data = Self.sendData(quote: Self.evmQuote(), prepared: prepared)

        #expect(data.feeData == nil)
        #expect(data.canSend == false)
    }
}

private struct StubExecutable: ISwapExecutable {}

private struct StubDisplayPrepared: IPreparedDisplay {
    let canSend: Bool
    let extraRateCoins: [Coin]

    func feeSections(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] {
        []
    }
}

private struct StubBroadcaster: ISwapBroadcaster {
    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_: IPrepared) async throws -> BroadcastResult {
        BroadcastResult(txHash: nil, trackingHandle: nil)
    }
}
