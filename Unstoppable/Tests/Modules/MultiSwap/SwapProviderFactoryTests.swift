import Combine
import Foundation
import MarketKit
import SwiftUI
import Testing
@testable import Unstoppable
@testable import WalletCore

@Suite(.serialized)
struct SwapProviderFactoryTests {
    init() {
        SwapProviderFactory.reset()
    }

    @Test func listsRegisteredProviders() throws {
        SwapProviderFactory.register([MatchingResolver.self])

        let provider = try #require(SwapProviderFactory.providers.first as? StubProvider)

        #expect(SwapProviderFactory.providers.count == 1)
        #expect(provider.id == "matching")
    }

    @Test func prependWinsOverRegisteredResolver() throws {
        SwapProviderFactory.register([MatchingResolver.self])
        SwapProviderFactory.prepend(PrependedResolver.self)

        let provider = try #require(SwapProviderFactory.provider(trackingProviderId: "any") as? StubProvider)

        #expect(provider.id == "prepended")
        #expect(SwapProviderFactory.providers.map(\.id) == ["prepended", "matching"])
    }

    @Test func emptyRegistryReturnsNothing() {
        #expect(SwapProviderFactory.provider(trackingProviderId: "any") == nil)
        #expect(SwapProviderFactory.providers.isEmpty)
    }

    @Test func decliningResolverIsSkippedForTracking() throws {
        SwapProviderFactory.register([DecliningResolver.self, MatchingResolver.self])

        let provider = try #require(SwapProviderFactory.provider(trackingProviderId: "any") as? StubProvider)

        #expect(provider.id == "matching")
    }

    @Test func duplicateIdsCollapseToTheFirstResolver() {
        SwapProviderFactory.register([MatchingResolver.self, MatchingResolver.self])

        #expect(SwapProviderFactory.providers.count == 1)
    }
}

private struct StubProvider: IMultiSwapProvider {
    let id: String

    func quotes(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> [MultiSwapQuote] {
        fatalError("not used")
    }

    func confirmationQuote(quote _: MultiSwapQuote, tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, slippage _: Decimal, recipient _: String?, transactionSettings _: TransactionSettings?) async throws -> SwapFinalQuote {
        fatalError("not used")
    }

    func preSwapView(step _: MultiSwapPreSwapStep, tokenIn _: Token, tokenOut _: Token, amount _: Decimal, isPresented _: Binding<Bool>, onSuccess _: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }

    func track(swap: Swap) async throws -> Swap {
        swap
    }
}

private enum MatchingResolver: ISwapProviderResolver {
    static var providers: [IMultiSwapProvider] {
        [StubProvider(id: "matching")]
    }

    static func provider(trackingProviderId _: String) -> IMultiSwapProvider? {
        StubProvider(id: "matching")
    }
}

private enum PrependedResolver: ISwapProviderResolver {
    static var providers: [IMultiSwapProvider] {
        [StubProvider(id: "prepended")]
    }

    static func provider(trackingProviderId _: String) -> IMultiSwapProvider? {
        StubProvider(id: "prepended")
    }
}

private enum DecliningResolver: ISwapProviderResolver {
    static var providers: [IMultiSwapProvider] {
        []
    }

    static func provider(trackingProviderId _: String) -> IMultiSwapProvider? {
        nil
    }
}
