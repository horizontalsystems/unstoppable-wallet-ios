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
    public var preciseEstimateTime: Bool { subProvider.info.preciseEstimateTime }
    public var icon: String { subProvider.info.icon }
    public var syncPublisher: AnyPublisher<Void, Never>? { subProvider.syncPublisher }

    public func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.slippageSupported(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        subProvider.supports(tokenIn: tokenIn, tokenOut: tokenOut)
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

    // No side effects: previews the route (with the user's fee setting) and estimates the fee against
    // the real deposit (signed / thorchain routes) or the stub (transfer providers). The order is
    // created in `commit(finalQuote:)` when the user confirms.
    public func confirmationQuote(
        multiSwapQuote: MultiSwapQuote,
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        recipient: String?,
        transactionSettings: TransactionSettings?
    ) async throws -> SwapFinalQuote {
        let result = try await subProvider.preview(
            input: USwapPreviewInput(
                multiSwapQuote: multiSwapQuote,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                slippage: slippage,
                recipient: recipient,
                transactionSettings: transactionSettings
            )
        )

        guard let previewToken = result.response.previewToken, !previewToken.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        guard !result.destinationAddress.isEmpty else {
            throw SwapError.missingDestinationAddress
        }

        if case let .thorchainDeposit(_, _, memo, _) = result.response.execution {
            try ThorChainSwapMemo.validate(memo, expectedDestination: result.destinationAddress, blockchainType: tokenOut.blockchainType)
        }

        let execution = result.response.execution
        let deposit: USwapFinalQuoteFactory.Input.Deposit?
        if let execution {
            deposit = USwapFinalQuoteFactory.Input.Deposit(instruction: execution.depositInstruction(), isStub: false)
        } else {
            // Transfer provider: the stub only serves the fee estimate, but without one there is
            // nothing to estimate against, so the preview fails rather than showing a quote with no
            // fee that could be sent.
            guard let stub = result.response.stubDepositAddress, !stub.isEmpty else {
                throw SwapError.noTransactionData
            }
            deposit = USwapFinalQuoteFactory.Input.Deposit(address: stub, attachment: nil, isStub: true)
        }

        let effectiveSlippage: Decimal? = result.response.minBuyAmount != nil ? slippage : nil
        let finalQuote = try await finalQuoteFactory.build(
            input: .init(
                tokenIn: tokenIn,
                amountIn: amountIn,
                response: result.response,
                providerSwapId: nil,
                destinationAddress: result.destinationAddress,
                slippage: effectiveSlippage,
                recipient: recipient,
                transactionSettings: transactionSettings,
                mevProtectionAllowed: Self.mevProtectionAllowed(execution: execution, tokenIn: tokenIn, tokenOut: tokenOut),
                deposit: deposit
            )
        )

        finalQuote.refundAddress = result.refundAddress
        finalQuote.minAmountOut = result.response.minBuyAmount
        // the stub is never shown as a deposit address
        if let execution, let instruction = execution.depositInstruction() {
            finalQuote.setDeposit(address: instruction.address, memo: instruction.attachment?.text)
        }
        finalQuote.providerContext = PreviewContext(
            previewToken: previewToken,
            tokenIn: tokenIn,
            amountIn: amountIn,
            slippage: effectiveSlippage,
            recipient: recipient,
            transactionSettings: transactionSettings,
            destinationAddress: result.destinationAddress,
            refundAddress: result.refundAddress,
            response: result.response
        )
        return finalQuote
    }

    // Creates the order (the only call with side effects). Transfer providers learn the deposit
    // address and attachment here, so their quote is rebuilt against the real deposit; for
    // signed / thorchain routes the preview's transaction is final and only gains the `uuid`.
    // Nothing visible on the previewed quote is written to (the screen is displaying it); the one
    // exception is the provider-private `providerContext`, cleared once its token is consumed.
    public func commit(finalQuote: SwapFinalQuote) async throws -> SwapCommitment {
        // Every quote this provider returns carries a context; a missing one can only mean the
        // token was already consumed, and a consumed preview must never be executed as-is.
        guard let context = finalQuote.providerContext as? PreviewContext else {
            throw SwapError.invalidTransactionData
        }

        // commit has side effects: never create an order from a cancelled task
        try Task.checkCancellation()

        let commit = try await subProvider.commit(previewToken: context.previewToken)

        // the token is consumed: a second slide on the same quote must re-preview, never re-commit
        finalQuote.providerContext = nil

        guard let uuid = commit.uuid, !uuid.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        if let execution = commit.execution {
            // A signed / thorchain / broker preview already carries its final transaction; a
            // different one at commit would mean signing something the user never reviewed.
            if let previewExecution = context.response.execution, !previewExecution.isTransfer {
                throw SwapError.invalidTransactionData
            }
            // Only a transfer is ever accepted at commit: it is rebuilt locally from the deposit
            // address and attachment, never signed from server-supplied transaction data.
            guard execution.isTransfer else {
                throw SwapError.invalidTransactionData
            }
            // The order's floor can only hold or improve on what the user confirmed.
            if let committedMin = commit.minBuyAmount, let previewedMin = context.response.minBuyAmount, committedMin < previewedMin {
                throw SwapError.invalidTransactionData
            }

            // The transfer always moves the amount the user saw: the commit's `sellAmount` /
            // `execution.amount` are not consulted.
            let response = context.response.merging(commit: commit)
            let instruction = execution.depositInstruction()

            let quote = try await finalQuoteFactory.build(
                input: .init(
                    tokenIn: context.tokenIn,
                    amountIn: context.amountIn,
                    response: response,
                    providerSwapId: uuid,
                    destinationAddress: context.destinationAddress,
                    slippage: context.slippage,
                    recipient: context.recipient,
                    transactionSettings: context.transactionSettings,
                    mevProtectionAllowed: false,
                    deposit: USwapFinalQuoteFactory.Input.Deposit(instruction: instruction, isStub: false)
                )
            )

            // e.g. the real deposit address needs more than the balance allows
            if let error = quote.transactionError {
                throw error
            }
            guard quote.canSwap else {
                throw SwapError.invalidTransactionData
            }

            quote.preciseEstimateTime = finalQuote.preciseEstimateTime
            quote.refundAddress = context.refundAddress
            quote.minAmountOut = commit.minBuyAmount ?? context.response.minBuyAmount
            if let instruction {
                quote.setDeposit(address: instruction.address, memo: instruction.attachment?.text)
            }
            return SwapCommitment(quote: quote, providerSwapId: uuid)
        }

        // No execution at commit: only a preview that carried its real execution (signed_transaction,
        // thorchain_deposit, stellar_broker, or a transfer already resolved at preview) can be
        // executed as previewed. A transfer preview built against the stub has nothing to send to.
        guard context.response.execution != nil else {
            throw SwapError.noTransactionData
        }
        guard finalQuote.canSwap, !(finalQuote.executable(tokenIn: context.tokenIn) is UnsupportedExecutable) else {
            throw SwapError.invalidTransactionData
        }

        return SwapCommitment(quote: finalQuote, providerSwapId: uuid)
    }

    public func reportInboundTxHash(providerSwapId: String, txHash: String) async throws {
        try await subProvider.reportSigned(uuid: providerSwapId, inboundTxHash: txHash)
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
    // What `commit(finalQuote:)` needs from the preview: the token to commit and everything the
    // final-quote factory needs to rebuild a transfer route against the real deposit.
    private final class PreviewContext {
        let previewToken: String
        let tokenIn: Token
        let amountIn: Decimal
        let slippage: Decimal?
        let recipient: String?
        let transactionSettings: TransactionSettings?
        let destinationAddress: String
        let refundAddress: String?
        let response: USwapMultiSwapApi.SwapResponse

        init(
            previewToken: String,
            tokenIn: Token,
            amountIn: Decimal,
            slippage: Decimal?,
            recipient: String?,
            transactionSettings: TransactionSettings?,
            destinationAddress: String,
            refundAddress: String?,
            response: USwapMultiSwapApi.SwapResponse
        ) {
            self.previewToken = previewToken
            self.tokenIn = tokenIn
            self.amountIn = amountIn
            self.slippage = slippage
            self.recipient = recipient
            self.transactionSettings = transactionSettings
            self.destinationAddress = destinationAddress
            self.refundAddress = refundAddress
            self.response = response
        }
    }

    static let legTypeNativeSend = "native_send"
    static let legTypeSwap = "swap"

    // MEV protection is a property of the route, not the provider: only a server-built signed
    // transaction on a Merkle-supported same-chain EVM pair can be broadcast through the private RPC.
    private static func mevProtectionAllowed(execution: USwapMultiSwapApi.Execution?, tokenIn: Token, tokenOut: Token) -> Bool {
        guard case .signedTransaction = execution else {
            return false
        }
        return MerkleTransactionAdapter.allowProtection(blockchainTypeIn: tokenIn.blockchainType, blockchainTypeOut: tokenOut.blockchainType)
    }

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
        case noXrpAdapter
        case noTronAdapter
        case noEvmAdapter
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
