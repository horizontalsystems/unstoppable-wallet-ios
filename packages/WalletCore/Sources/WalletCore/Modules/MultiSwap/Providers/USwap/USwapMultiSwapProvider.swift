import Combine
import Foundation
import MarketKit
import SwiftUI

public final class USwapMultiSwapProvider: IMultiSwapProvider {
    private let subProvider: USwapSubProvider
    private let rateQuoteFactory: USwapRateQuoteFactory
    private let finalQuoteFactory: USwapFinalQuoteFactory

    public init(
        subProvider: USwapSubProvider,
        rateQuoteFactory: USwapRateQuoteFactory,
        finalQuoteFactory: USwapFinalQuoteFactory
    ) {
        self.subProvider = subProvider
        self.rateQuoteFactory = rateQuoteFactory
        self.finalQuoteFactory = finalQuoteFactory
    }

    public var id: String { subProvider.info.id }
    public var name: String { subProvider.info.name }
    public var type: SwapProviderType { subProvider.info.type }
    public var requireTerms: Bool { subProvider.info.requireTerms }
    public var icon: String { subProvider.info.icon }
    public var syncPublisher: AnyPublisher<Void, Never>? { subProvider.syncPublisher }

    public func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.slippageSupported(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.supports(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    public func mevProtectionAllowed(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.mevProtectionAllowed(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    public func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
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

    public func confirmationQuote(
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
        finalQuote.minAmountOut = result.response.minBuyAmount
        return finalQuote
    }

    public func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool? {
        try await subProvider.validateTrustedProvider(tokenIn: tokenIn, amountIn: amountIn)
    }

    public func preSwapView(
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

    public func track(swap: Swap) async throws -> Swap {
        try await subProvider.track(swap: swap)
    }
}

extension USwapMultiSwapProvider {
    static let legTypeNativeSend = "native_send"
    static let legTypeSwap = "swap"

    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noRoutes
        case noTransactionData
        case invalidTransactionData
        case missingDestinationAddress
        case noZcashAdapter
        case noTonAdapter
        case noStellarAdapter
        case noMoneroAdapter
        case noZanoAdapter
        case noSolanaAdapter
    }
}

final class USwapMultiSwapQuote: MultiSwapQuote, USwapRateResult.Carrying {
    let replay: (any USwapRateResult.Replay)?

    init(expectedBuyAmount: Decimal, estimatedTime: TimeInterval? = nil, replay: (any USwapRateResult.Replay)?) {
        self.replay = replay
        super.init(expectedBuyAmount: expectedBuyAmount, estimatedTime: estimatedTime)
    }
}

final class USwapEvmMultiSwapQuote: EvmMultiSwapQuote, USwapRateResult.Carrying {
    let replay: (any USwapRateResult.Replay)?

    init(
        expectedBuyAmount: Decimal,
        allowanceState: MultiSwapAllowanceHelper.AllowanceState,
        estimatedTime: TimeInterval? = nil,
        replay: (any USwapRateResult.Replay)?
    ) {
        self.replay = replay
        super.init(expectedBuyAmount: expectedBuyAmount, allowanceState: allowanceState, estimatedTime: estimatedTime)
    }
}
