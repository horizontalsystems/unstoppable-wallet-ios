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

    private static func evmQuote(canSwap: Bool = true, transactionError: Error? = nil) -> EvmSwapFinalQuote {
        EvmSwapFinalQuote(
            expectedBuyAmount: 1,
            transactionData: canSwap ? try? TransactionData(
                to: EvmKit.Address(hex: "0x1234567890123456789012345678901234567890"),
                value: 100,
                input: Data()
            ) : nil,
            transactionError: transactionError,
            slippage: nil,
            recipient: nil,
            gasPrice: canSwap ? .legacy(gasPrice: 1_000_000_000) : nil,
            evmFeeData: canSwap ? EvmFeeData(gasLimit: 100_000, surchargedGasLimit: 110_000) : nil,
            nonce: nil,
            toAddress: "to"
        )
    }

    private enum TestError: Error {
        case estimateFailed
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

    @Test func directSectionsAppendQuoteFeeFields() {
        let quote = Self.evmQuote()
        let data = Self.sendData(quote: quote, prepared: DirectPrepared(executable: StubExecutable()))
        let baseToken = Self.token(uid: "base")
        let currency = Currency(code: "USD", symbol: "$", decimal: 2)

        let sections = data.sections(baseToken: baseToken, currency: currency, rates: [:])
        let quoteFields = quote.fields(tokenIn: data.tokenIn, tokenOut: data.tokenOut, baseToken: baseToken, currency: currency, tokenInRate: nil, tokenOutRate: nil, baseTokenRate: nil)
        let feeFields = quote.feeFields(baseToken: baseToken, currency: currency, baseTokenRate: nil)

        #expect(sections.count == 2) // flow + info(+fee), no otherSections
        #expect(feeFields.isEmpty == false) // populated EVM quote produces fee rows
        #expect(sections[1].fields.count == 1 + quoteFields.count + feeFields.count) // price + quote + fee
    }

    @Test func displaySectionsReplaceQuoteFeeRowsWithFeeSections() {
        let quote = Self.evmQuote()
        let prepared = StubDisplayPrepared(canSend: true, extraRateCoins: [], stubFeeSections: [SendDataSection([])])
        let data = Self.sendData(quote: quote, prepared: prepared)
        let baseToken = Self.token(uid: "base")
        let currency = Currency(code: "USD", symbol: "$", decimal: 2)

        let sections = data.sections(baseToken: baseToken, currency: currency, rates: [:])
        let quoteFields = quote.fields(tokenIn: data.tokenIn, tokenOut: data.tokenOut, baseToken: baseToken, currency: currency, tokenInRate: nil, tokenOutRate: nil, baseTokenRate: nil)

        #expect(sections.count == 3) // flow + info + the display fee section
        #expect(sections[1].fields.count == 1 + quoteFields.count) // price + quote, NO quote fee rows
    }

    @Test func directPreparedKeepsQuoteTransactionErrorCaution() {
        let quote = Self.evmQuote(canSwap: false, transactionError: TestError.estimateFailed)
        let data = Self.sendData(quote: quote, prepared: DirectPrepared(executable: StubExecutable()))

        let cautions = data.cautions(baseToken: Self.token(uid: "base"), currency: Currency(code: "USD", symbol: "$", decimal: 2), rates: [:])

        #expect(cautions.isEmpty == false) // native-path caution rendered for EOA
    }

    @Test func displayPreparedDropsQuoteTransactionErrorCaution() {
        let quote = Self.evmQuote(canSwap: false, transactionError: TestError.estimateFailed)
        let prepared = StubDisplayPrepared(canSend: true, extraRateCoins: [])
        let data = Self.sendData(quote: quote, prepared: prepared)

        let cautions = data.cautions(baseToken: Self.token(uid: "base"), currency: Currency(code: "USD", symbol: "$", decimal: 2), rates: [:])

        #expect(cautions.isEmpty) // the prepared owns the payment view; quote's native caution not rendered
    }

    @Test func displayPreparedSurfacesItsOwnCautions() {
        let quote = Self.evmQuote(canSwap: false, transactionError: TestError.estimateFailed)
        let prepared = StubDisplayPrepared(canSend: false, extraRateCoins: [], stubCautions: [CautionNew(title: "Reserve", text: "not enough", type: .error)])
        let data = Self.sendData(quote: quote, prepared: prepared)

        let cautions = data.cautions(baseToken: Self.token(uid: "base"), currency: Currency(code: "USD", symbol: "$", decimal: 2), rates: [:])

        #expect(cautions.count == 1)
        #expect(cautions[0].title == "Reserve")
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
    var stubFeeSections: [SendDataSection] = []
    var stubCautions: [CautionNew] = []

    func feeSections(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] {
        stubFeeSections
    }

    func cautions(baseToken _: Token) -> [CautionNew] {
        stubCautions
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
