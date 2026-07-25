import Combine
import Foundation
import MarketKit
import SwiftUI

final class USwapMultiSwapProviderNew: IMultiSwapProvider {
    private let subProvider: USwapSubProvider
    private let rateQuoteFactory: USwapRateQuoteFactory
    private let finalQuoteFactory: USwapFinalQuoteFactory

    init(
        subProvider: USwapSubProvider,
        rateQuoteFactory: USwapRateQuoteFactory,
        finalQuoteFactory: USwapFinalQuoteFactory
    ) {
        self.subProvider = subProvider
        self.rateQuoteFactory = rateQuoteFactory
        self.finalQuoteFactory = finalQuoteFactory
    }

    var id: String { subProvider.info.id }
    var name: String { subProvider.info.name }
    var type: SwapProviderType { subProvider.info.type }
    var requireTerms: Bool { subProvider.info.requireTerms }
    var icon: String { subProvider.info.icon }
    var syncPublisher: AnyPublisher<Void, Never>? { subProvider.syncPublisher }

    func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.slippageSupported(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.supports(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    func mevProtectionAllowed(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.mevProtectionAllowed(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        let result = try await subProvider.rate(
            input: USwapRateInput(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                slippage: MultiSwapSlippage.default
            )
        )

        return try await rateQuoteFactory.build(
            input: .init(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                response: result.response,
                replay: result.replay
            )
        )
    }

    func confirmationQuote(
        multiSwapQuote: MultiSwapQuote,
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        recipient: String?,
        transactionSettings: TransactionSettings?
    ) async throws -> SwapFinalQuote {
        let result = try await subProvider.commit(
            input: USwapCommitInput(
                multiSwapQuote: multiSwapQuote,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                slippage: slippage,
                recipient: recipient,
                transactionSettings: transactionSettings
            )
        )

        guard let providerSwapId = result.response.uuid, !providerSwapId.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        guard !result.destinationAddress.isEmpty else {
            throw SwapError.missingDestinationAddress
        }

        let effectiveSlippage: Decimal? = result.response.minBuyAmount != nil ? slippage : nil
        let finalQuote = try await finalQuoteFactory.build(
            input: .init(
                tokenIn: tokenIn,
                amountIn: amountIn,
                response: result.response,
                providerSwapId: providerSwapId,
                destinationAddress: result.destinationAddress,
                slippage: effectiveSlippage,
                recipient: recipient,
                transactionSettings: transactionSettings
            )
        )

        finalQuote.refundAddress = result.refundAddress
        return finalQuote
    }

    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool? {
        try await subProvider.validateTrustedProvider(tokenIn: tokenIn, amountIn: amountIn)
    }

    func preSwapView(
        step: MultiSwapPreSwapStep,
        tokenIn: Token,
        tokenOut _: Token,
        amount: Decimal,
        isPresented: Binding<Bool>,
        onSuccess: @escaping () -> Void
    ) -> AnyView {
        rateQuoteFactory.preSwapView(
            step: step,
            tokenIn: tokenIn,
            amount: amount,
            isPresented: isPresented,
            onSuccess: onSuccess
        ) ?? AnyView(Text("Invalid Pre Swap Step"))
    }

    func track(swap: Swap) async throws -> Swap {
        try await subProvider.track(swap: swap)
    }
}

extension USwapMultiSwapProviderNew {
    enum SwapError: Error {
        case invalidTransactionData
        case missingDestinationAddress
    }
}
