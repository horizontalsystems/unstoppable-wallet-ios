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

    @Test func resolvesRegisteredResolver() throws {
        SwapProviderFactory.register([MatchingResolver.self])

        let provider = try #require(SwapProviderFactory.provider(id: "matching") as? StubProvider)
        let info = try #require(SwapProviderFactory.providerInfo(id: "matching"))

        #expect(provider.id == "matching")
        #expect(info.id == provider.id)
        #expect(SwapProviderFactory.providerName(id: "matching") == info.name)
    }

    @Test func prependWinsOverRegisteredResolver() throws {
        SwapProviderFactory.register([MatchingResolver.self])
        SwapProviderFactory.prepend(PrependedResolver.self)

        let provider = try #require(SwapProviderFactory.provider(id: "matching") as? StubProvider)

        #expect(provider.id == "prepended")
    }

    @Test func emptyRegistryReturnsNil() {
        #expect(SwapProviderFactory.provider(id: "matching") == nil)
    }

    @Test func decliningResolverIsSkipped() throws {
        SwapProviderFactory.register([DecliningResolver.self, MatchingResolver.self])

        let provider = try #require(SwapProviderFactory.provider(id: "matching") as? StubProvider)

        #expect(provider.id == "matching")
    }
}

private struct StubProvider: IMultiSwapProvider {
    let id: String

    var name: String { id }
    var type: SwapProviderType { .good }
    var icon: String { "stub" }

    func supports(tokenIn _: Token, tokenOut _: Token) -> Bool {
        false
    }

    func quote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> MultiSwapQuote {
        fatalError("not used")
    }

    func confirmationQuote(multiSwapQuote _: MultiSwapQuote, tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, slippage _: Decimal, recipient _: String?, transactionSettings _: TransactionSettings?) async throws -> SwapFinalQuote {
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
    static func providerInfo(id: String) -> USwapProviderInfo? {
        id == "matching"
            ? USwapProviderInfo(id: "matching", name: "Matching", icon: "matching", type: .good, requireTerms: false)
            : nil
    }

    static func provider(id: String) -> IMultiSwapProvider? {
        id == "matching" ? StubProvider(id: "matching") : nil
    }
}

private enum PrependedResolver: ISwapProviderResolver {
    static func provider(id: String) -> IMultiSwapProvider? {
        id == "matching" ? StubProvider(id: "prepended") : nil
    }
}

private enum DecliningResolver: ISwapProviderResolver {
    static func provider(id _: String) -> IMultiSwapProvider? {
        nil
    }
}
