import Foundation
import Testing
@testable import WalletCore

/// Quote ranking and selection on the swap screen: best by amount, the user's pick while it is still
/// quoted, duplicates collapsed to the higher amount, the "fastest" sort.
struct MultiSwapQuoteSelectorTests {
    private struct Quote: QuoteLike, Equatable {
        let key: String
        let expectedBuyAmount: Decimal
        let estimatedTime: TimeInterval?
    }

    private static let slowBest = Quote(key: "USWAP:EXOLIX", expectedBuyAmount: 10, estimatedTime: 1800)
    private static let fast = Quote(key: "USWAP:THORCHAIN", expectedBuyAmount: 9, estimatedTime: 600)
    private static let timeless = Quote(key: "USWAP:NEAR", expectedBuyAmount: 9, estimatedTime: nil)

    @Test func bestIsTheHighestAmount() {
        #expect(MultiSwapQuoteSelector.best([Self.fast, Self.slowBest, Self.timeless]) == Self.slowBest)
        #expect(MultiSwapQuoteSelector.best([Quote]()) == nil)
    }

    @Test func currentFollowsUserSelectionWhileQuoted() {
        let quotes = [Self.slowBest, Self.fast]

        #expect(MultiSwapQuoteSelector.current(quotes: quotes, userSelectedKey: "USWAP:THORCHAIN", best: Self.slowBest) == Self.fast)
        #expect(MultiSwapQuoteSelector.current(quotes: quotes, userSelectedKey: nil, best: Self.slowBest) == Self.slowBest)
        // the picked venue dropped out of the round: fall back to the best
        #expect(MultiSwapQuoteSelector.current(quotes: quotes, userSelectedKey: "USWAP:GONE", best: Self.slowBest) == Self.slowBest)
    }

    @Test func duplicateKeysKeepTheHigherAmount() {
        let lower = Quote(key: "USWAP:EXOLIX", expectedBuyAmount: 8, estimatedTime: 100)
        let higher = Quote(key: "USWAP:EXOLIX", expectedBuyAmount: 10, estimatedTime: 200)

        #expect(MultiSwapQuoteSelector.dedupe([lower, Self.fast, higher]) == [higher, Self.fast])
        #expect(MultiSwapQuoteSelector.dedupe([higher, lower]) == [higher])
    }

    @Test func bestRateSortsByAmount() {
        #expect(MultiSwapQuoteSelector.sorted([Self.fast, Self.slowBest, Self.timeless], by: .bestRate) == [Self.slowBest, Self.fast, Self.timeless])
    }

    @Test func bestTimeSortsByTimeThenAmountWithUnknownLast() {
        let fastButSmaller = Quote(key: "USWAP:MAYA", expectedBuyAmount: 8, estimatedTime: 600)

        #expect(MultiSwapQuoteSelector.sorted([Self.timeless, Self.slowBest, fastButSmaller, Self.fast], by: .bestTime) == [Self.fast, fastButSmaller, Self.slowBest, Self.timeless])
    }
}
