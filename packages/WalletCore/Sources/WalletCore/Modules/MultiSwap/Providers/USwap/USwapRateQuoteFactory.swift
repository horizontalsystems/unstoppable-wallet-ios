import Foundation
import MarketKit
import SwiftUI

protocol USwapRateQuoteBuilder {
    func supports(tokenIn: Token) -> Bool
    func build(input: USwapRateQuoteFactory.Input) async throws -> MultiSwapQuote
    func preSwapView(
        step: MultiSwapPreSwapStep,
        tokenIn: Token,
        amount: Decimal,
        isPresented: Binding<Bool>,
        onSuccess: @escaping () -> Void
    ) -> AnyView?
}

extension USwapRateQuoteBuilder {
    func preSwapView(
        step _: MultiSwapPreSwapStep,
        tokenIn _: Token,
        amount _: Decimal,
        isPresented _: Binding<Bool>,
        onSuccess _: @escaping () -> Void
    ) -> AnyView? {
        nil
    }
}

final class USwapRateQuoteFactory {
    struct Input {
        let tokenIn: Token
        let tokenOut: Token
        let amountIn: Decimal
        let response: USwapMultiSwapApi.RateQuote
        let replay: (any USwapRateResult.Replay)?

        init(
            tokenIn: Token,
            tokenOut: Token,
            amountIn: Decimal,
            response: USwapMultiSwapApi.RateQuote,
            replay: (any USwapRateResult.Replay)? = nil
        ) {
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.amountIn = amountIn
            self.response = response
            self.replay = replay
        }
    }

    enum FactoryError: Error {
        case unsupportedBuilder
        case ambiguousBuilders
    }

    private let builders: [USwapRateQuoteBuilder]

    init(builders: [USwapRateQuoteBuilder]) {
        self.builders = builders
    }

    func build(input: Input) async throws -> MultiSwapQuote {
        try await builder(tokenIn: input.tokenIn).build(input: input)
    }

    func preSwapView(
        step: MultiSwapPreSwapStep,
        tokenIn: Token,
        amount: Decimal,
        isPresented: Binding<Bool>,
        onSuccess: @escaping () -> Void
    ) -> AnyView? {
        guard let builder = try? builder(tokenIn: tokenIn) else {
            return nil
        }

        return builder.preSwapView(
            step: step,
            tokenIn: tokenIn,
            amount: amount,
            isPresented: isPresented,
            onSuccess: onSuccess
        )
    }

    private func builder(tokenIn: Token) throws -> USwapRateQuoteBuilder {
        let matchingBuilders = builders.filter { $0.supports(tokenIn: tokenIn) }

        guard matchingBuilders.count == 1 else {
            if matchingBuilders.isEmpty {
                throw FactoryError.unsupportedBuilder
            } else {
                throw FactoryError.ambiguousBuilders
            }
        }

        return matchingBuilders[0]
    }
}
