import Combine
import Foundation
import MarketKit
import SwiftUI

/// The one swap provider. One `/v3/rate` per round answers with every venue's route; each becomes a
/// quote whose `id` is the venue id, handed back here for the preview (`/v3/preview` with that
/// `provider`), the AML precheck and the commit. Venue identity comes from `MultiSwapProviderManager`,
/// token identifiers from `USwapAssetCatalog`, Zcash addresses from the route's `addressRules`.
public final class USwapMultiSwapProvider: IMultiSwapProvider {
    public let id = "USWAP"

    private let api: USwapMultiSwapApi
    private let assetCatalog: USwapAssetCatalog
    private let commitRequestBuilder: USwapCommitRequestBuilder
    private let tracker: USwapTracker
    private let rateQuoteFactory: USwapRateQuoteFactory
    private let finalQuoteFactory: USwapFinalQuoteFactory
    private let providerManager: MultiSwapProviderManager

    init(
        api: USwapMultiSwapApi,
        assetCatalog: USwapAssetCatalog,
        commitRequestBuilder: USwapCommitRequestBuilder,
        tracker: USwapTracker,
        rateQuoteFactory: USwapRateQuoteFactory,
        finalQuoteFactory: USwapFinalQuoteFactory,
        providerManager: MultiSwapProviderManager
    ) {
        self.api = api
        self.assetCatalog = assetCatalog
        self.commitRequestBuilder = commitRequestBuilder
        self.tracker = tracker
        self.rateQuoteFactory = rateQuoteFactory
        self.finalQuoteFactory = finalQuoteFactory
        self.providerManager = providerManager
    }

    public var syncPublisher: AnyPublisher<Void, Never>? {
        assetCatalog.syncPublisher
    }

    public func startSession() {
        api.sessionId = UUID().uuidString
    }

    public func slippageSupported(tokenIn _: Token, tokenOut _: Token) -> Bool {
        true
    }

    public func quotes(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> [MultiSwapQuote] {
        let (assetIn, assetOut) = try assets(tokenIn: tokenIn, tokenOut: tokenOut)

        // Preserve the dry-quote destination resolution and cache so a generated address is replayed
        // by the same request builder at preview. Best-effort: the account may be unable to receive
        // tokenOut at all (external-recipient swap) — the recipient entered before confirmation then
        // supplies the destination, so a failed resolution must not kill the dry quote.
        _ = try? await commitRequestBuilder.destinationAddress(recipient: nil, tokenIn: tokenIn, tokenOut: tokenOut, kind: .transparent)

        let request = USwapMultiSwapApi.RateRequest(
            sellAsset: assetIn,
            buyAsset: assetOut,
            sellAmount: amountIn,
            slippage: MultiSwapSlippage.default,
            chainId: commitRequestBuilder.chainId(token: tokenIn)
        )
        let result = try await api.rate(request)

        let routes = USwapRouteFilter.filter(result.quotes, tokenIn: tokenIn, executionType: providerManager.executionType(providerId:))

        guard !routes.isEmpty else {
            throw SwapError.noRoutes
        }

        let venues = routes.map { route in
            let venue = providerManager.venue(id: route.providerId)

            if !venue.isKnown {
                providerManager.requestSync(unknownProviderId: route.providerId)
            }

            return venue.overriding(amlPolicy: route.amlPolicy)
        }

        // Built in parallel (the allowance builder reads the chain); the backend's order is kept.
        let built: [(index: Int, quote: MultiSwapQuote)] = await withTaskGroup(of: (Int, MultiSwapQuote?).self) { group in
            for (index, route) in routes.enumerated() {
                let venue = venues[index]

                group.addTask { [rateQuoteFactory] in
                    do {
                        let quote = try await rateQuoteFactory.build(
                            input: .init(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, response: route, venue: venue)
                        )
                        quote.activationAsset = StellarActivationHelper.activationRequiredAsset(tokenOut: tokenOut)
                        return (index, quote)
                    } catch {
                        print("QUOTE BUILD ERROR: \(venue.id): \(error)")
                        return (index, nil)
                    }
                }
            }

            var built = [(index: Int, quote: MultiSwapQuote)]()

            for await (index, quote) in group {
                if let quote {
                    built.append((index, quote))
                }
            }

            return built
        }

        let quotes = built.sorted { $0.index < $1.index }.map(\.quote)

        guard !quotes.isEmpty else {
            throw SwapError.noRoutes
        }

        return quotes
    }

    /// No side effects: previews the route (with the user's fee setting) and estimates the fee against
    /// the real deposit (signed / thorchain routes) or the stub (transfer providers). The order is
    /// created in `commit(finalQuote:)` when the user confirms.
    public func confirmationQuote(
        quote: MultiSwapQuote,
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        recipient: String?,
        transactionSettings: TransactionSettings?
    ) async throws -> SwapFinalQuote {
        let (assetIn, assetOut) = try assets(tokenIn: tokenIn, tokenOut: tokenOut)
        let quoteId = quote.id

        // A typed ZEC recipient must fit the route's destination rule before anything is previewed: a
        // transparent-only route would refuse a unified address at commit, after the deposit is built.
        // Run against the quote's rules first and again against the rules a `400` corrects them to.
        func validateRecipient(rules: USwapMultiSwapApi.ZcashAddressRules?) throws {
            guard tokenOut.blockchainType == .zcash, let recipient else {
                return
            }

            do {
                try USwapZcashAddressPolicy.validateRecipient(
                    recipient,
                    kind: Self.destinationKind(quote: quote, rules: rules, tokenIn: tokenIn),
                    acceptsTex: USwapZcashAddressPolicy.destinationAcceptsTex(rules: rules),
                    acceptsTransparent: USwapZcashAddressPolicy.destinationAcceptsTransparent(
                        rules: rules,
                        sellBlockchainType: tokenIn.blockchainType,
                        executionType: quote.venue.executionType
                    )
                )
            } catch {
                throw SwapError.recipientNotAccepted
            }
        }

        try validateRecipient(rules: quote.zcashAddressRules)

        func build(addressRules: USwapMultiSwapApi.ZcashAddressRules?) async throws -> USwapMultiSwapApi.SwapRequest {
            try await commitRequestBuilder.build(
                venueId: quoteId,
                addressRules: addressRules,
                destinationKind: Self.destinationKind(quote: quote, rules: addressRules, tokenIn: tokenIn),
                sellAsset: assetIn,
                buyAsset: assetOut,
                sellAmount: amountIn,
                slippage: slippage,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: recipient,
                transactionSettings: transactionSettings
            )
        }

        var request = try await build(addressRules: quote.zcashAddressRules)
        let response: USwapMultiSwapApi.SwapResponse

        do {
            response = try await api.preview(request)
        } catch {
            if error is CancellationError {
                throw error
            }

            // A Zcash address the route does not take: re-preview ONCE with the addresses the server's
            // rules point to; a second refusal shows the server's message.
            guard let addressError = USwapMultiSwapApi.previewAddressError(networkError: error) else {
                throw Self.previewError(error)
            }

            guard let correctedRules = addressError.addressRules else {
                throw SwapError.previewAddressRejected(message: addressError.message)
            }

            // the typed recipient must fit the corrected rules too, or the re-preview would only fail again
            try validateRecipient(rules: correctedRules)

            request = try await build(addressRules: correctedRules)

            do {
                response = try await api.preview(request)
            } catch {
                if let secondError = USwapMultiSwapApi.previewAddressError(networkError: error) {
                    throw SwapError.previewAddressRejected(message: secondError.message)
                }

                throw Self.previewError(error)
            }
        }

        // The preview may name a precheck the rate route did not (or a different one): the check already
        // run on the swap screen did not cover it, so it runs here and fails closed.
        if USwapAmlPrecheck.isRequired(amlProviderId: response.amlProviderId), let previewAmlProviderId = response.amlProviderId,
           previewAmlProviderId != quote.amlProviderId
        {
            switch try await senderPrecheck(amlProviderId: previewAmlProviderId, tokenIn: tokenIn) {
            case true?: break
            case false?: throw SwapError.amlCheckFailed
            // no "continue anyway" sheet on the confirmation screen: an unprocessed verdict fails closed
            case nil: throw SwapError.amlCheckUnprocessed
            }
        }

        return try await Self.assembleFinalQuote(
            response: response,
            request: request,
            venueId: quoteId,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            recipient: recipient,
            transactionSettings: transactionSettings,
            finalQuoteFactory: finalQuoteFactory
        )
    }

    /// The previewed route as the confirmation screen's quote: the memo check, the deposit the fee is
    /// estimated against (real or stub), the display metadata and the commit context. Static so it can
    /// be exercised with a canned response.
    static func assembleFinalQuote(
        response: USwapMultiSwapApi.SwapResponse,
        request: USwapMultiSwapApi.SwapRequest,
        venueId: String,
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        recipient: String?,
        transactionSettings: TransactionSettings?,
        finalQuoteFactory: USwapFinalQuoteFactory
    ) async throws -> SwapFinalQuote {
        guard let previewToken = response.previewToken, !previewToken.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        guard !request.destinationAddress.isEmpty else {
            throw SwapError.missingDestinationAddress
        }

        if case let .thorchainDeposit(_, _, memo, _) = response.execution {
            try ThorChainSwapMemo.validate(memo, expectedDestination: request.destinationAddress, blockchainType: tokenOut.blockchainType)

            // The actual instruction, not the synced directory, decides: a vault deposit from an
            // OP_RETURN-memo chain cannot carry a shielded ZEC destination in its memo, so only a
            // transparent or TEX destination is deliverable whatever the rules recommended.
            if tokenIn.blockchainType.memoRidesOpReturn, tokenOut.blockchainType == .zcash,
               !USwapZcashAddressPolicy.isTransparentOrTex(request.destinationAddress)
            {
                throw SwapError.destinationNotDeliverable
            }
        }

        let execution = response.execution
        let deposit: USwapFinalQuoteFactory.Input.Deposit?
        if let execution {
            deposit = USwapFinalQuoteFactory.Input.Deposit(instruction: execution.depositInstruction(), isStub: false)
        } else {
            // Transfer provider: the stub only serves the fee estimate, but without one there is
            // nothing to estimate against, so the preview fails rather than showing a quote with no
            // fee that could be sent.
            guard let stub = response.stubDepositAddress, !stub.isEmpty else {
                throw SwapError.noTransactionData
            }
            deposit = USwapFinalQuoteFactory.Input.Deposit(address: stub, attachment: nil, isStub: true)
        }

        let effectiveSlippage: Decimal? = response.minBuyAmount != nil ? slippage : nil
        let finalQuote = try await finalQuoteFactory.build(
            input: .init(
                tokenIn: tokenIn,
                amountIn: amountIn,
                response: response,
                providerSwapId: nil,
                destinationAddress: request.destinationAddress,
                slippage: effectiveSlippage,
                recipient: recipient,
                transactionSettings: transactionSettings,
                mevProtectionAllowed: mevProtectionAllowed(execution: execution, tokenIn: tokenIn, tokenOut: tokenOut),
                deposit: deposit
            )
        )

        finalQuote.refundAddress = request.refundAddress
        finalQuote.minAmountOut = response.minBuyAmount
        // the stub is never shown as a deposit address
        if let execution, let instruction = execution.depositInstruction() {
            finalQuote.setDeposit(address: instruction.address, memo: instruction.attachment?.text)
        }
        finalQuote.providerContext = PreviewContext(
            previewToken: previewToken,
            venueId: venueId,
            tokenIn: tokenIn,
            amountIn: amountIn,
            slippage: effectiveSlippage,
            recipient: recipient,
            transactionSettings: transactionSettings,
            destinationAddress: request.destinationAddress,
            refundAddress: request.refundAddress,
            response: response
        )
        return finalQuote
    }

    /// Creates the order (the only call with side effects). Transfer providers learn the deposit
    /// address and attachment here, so their quote is rebuilt against the real deposit; for
    /// signed / thorchain routes the preview's transaction is final and only gains the `uuid`.
    /// Nothing visible on the previewed quote is written to (the screen is displaying it); the one
    /// exception is the provider-private `providerContext`, cleared once its token is consumed.
    public func commit(finalQuote: SwapFinalQuote) async throws -> SwapCommitment {
        // Every quote this provider returns carries a context; a missing one can only mean the
        // token was already consumed, and a consumed preview must never be executed as-is.
        guard let context = finalQuote.providerContext as? PreviewContext else {
            throw SwapError.invalidTransactionData
        }

        // commit has side effects: never create an order from a cancelled task
        try Task.checkCancellation()

        let commit: USwapMultiSwapApi.CommitResponse
        do {
            commit = try await api.commit(.init(previewToken: context.previewToken))
        } catch {
            if error is CancellationError {
                throw error
            }

            let commitError = USwapMultiSwapApi.commitError(networkError: error)

            // A blacklisted address: the server's text is what the user sees, nothing is signed.
            if commitError.isAddressBlacklisted {
                throw SwapError.addressBlacklisted(message: commitError.providerError?.message ?? commitError.reason ?? "")
            }

            throw commitError
        }

        // the token is consumed: a second slide on the same quote must re-preview, never re-commit
        finalQuote.providerContext = nil

        guard let uuid = commit.uuid, !uuid.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        if let execution = commit.execution {
            // A signed / thorchain preview already carries its final transaction; a
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

            quote.refundAddress = context.refundAddress
            quote.minAmountOut = commit.minBuyAmount ?? context.response.minBuyAmount
            if let instruction {
                quote.setDeposit(address: instruction.address, memo: instruction.attachment?.text)
            }
            return SwapCommitment(quote: quote, providerSwapId: uuid)
        }

        // No execution at commit: only a preview that carried its real execution (signed_transaction,
        // thorchain_deposit, or a transfer already resolved at preview) can be
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
        _ = try await api.signed(.init(uuid: providerSwapId, inboundTxHash: txHash))
    }

    /// The route's AML address precheck, run only when the selected quote carries `amlProviderId`, on the
    /// SENDER addresses only (the UTXOs or account funding the deposit) — never the recipient, a refund
    /// or a generated destination — with the id passed verbatim. A quote without the field has no
    /// precheck and passes; a sender set that cannot be determined throws `amlCheckInconclusive` (fails
    /// closed); the backend's own "unprocessed" verdict is nil.
    public func validateTrustedProvider(quote: MultiSwapQuote, tokenIn: Token, amountIn _: Decimal) async throws -> Bool? {
        if let result = Core.instance?.localStorage.debuggingAmlCheckResult {
            return result == .dirty ? false : nil
        }

        guard USwapAmlPrecheck.isRequired(amlProviderId: quote.amlProviderId), let amlProviderId = quote.amlProviderId else {
            return true
        }

        return try await senderPrecheck(amlProviderId: amlProviderId, tokenIn: tokenIn)
    }

    /// The backend's verdict: `true` passed, `false` failed, nil unprocessed. A sender set that cannot be
    /// determined is not a verdict: it throws `amlCheckInconclusive`, which fails closed.
    private func senderPrecheck(amlProviderId: String, tokenIn: Token) async throws -> Bool? {
        let sender = await DestinationHelper.sourceAddresses(token: tokenIn)
        try Task.checkCancellation()

        let addresses = USwapAmlPrecheck.addresses(sender: sender)

        guard !addresses.isEmpty else {
            throw SwapError.amlCheckInconclusive
        }

        return try await api.checkAddresses(.init(addresses: addresses, amlProviderId: amlProviderId))
    }

    public func preSwapView(
        step: MultiSwapPreSwapStep,
        tokenIn: Token,
        tokenOut: Token,
        amount: Decimal,
        isPresented: Binding<Bool>,
        onSuccess: @escaping () -> Void
    ) -> AnyView {
        if let view = StellarActivationHelper.preSwapView(step: step, tokenOut: tokenOut, isPresented: isPresented, onSuccess: onSuccess) {
            return view
        }

        return rateQuoteFactory.preSwapView(
            step: step,
            tokenIn: tokenIn,
            amount: amount,
            isPresented: isPresented,
            onSuccess: onSuccess
        ) ?? AnyView(Text("Invalid Pre Swap Step"))
    }

    public func track(swap: Swap) async throws -> Swap {
        let request: USwapMultiSwapApi.TrackRequest = swap.operation == .splitSwap
            ? .split(splitUuid: swap.providerSwapId, inboundTxHash: swap.txHash)
            : .swap(uuid: swap.providerSwapId, inboundTxHash: swap.txHash)

        return try await tracker.track(swap: swap, request: request)
    }
}

extension USwapMultiSwapProvider: ISplitSwapProvider {
    public func splitQuotes(tokenIn: Token, tokenOut: Token, amountIn: Decimal, percents: [Int]) async throws -> [SplitMultiSwapQuote] {
        guard percents.reduce(0, +) == 100 else {
            throw SplitSwapError.invalidPercents
        }

        let (assetIn, assetOut) = try assets(tokenIn: tokenIn, tokenOut: tokenOut)

        let request = USwapMultiSwapApi.SplitRequest(
            sellAsset: assetIn,
            sellAmount: amountIn,
            slippage: MultiSwapSlippage.default,
            chainId: commitRequestBuilder.chainId(token: tokenIn),
            outputs: percents.map { .init(buyAsset: assetOut, percent: $0) }
        )

        let result = try await api.splitRate(request)

        let quotes = result.routes.compactMap { route -> SplitMultiSwapQuote? in
            guard route.outputs.count == percents.count, !route.providerId.isEmpty else {
                return nil
            }

            return SplitMultiSwapQuote(
                id: route.providerId,
                venue: providerManager.venue(id: route.providerId),
                percents: percents,
                outputAmounts: route.outputs.map(\.expectedBuyAmount),
                guaranteedAmountOut: route.minBuyAmount,
                estimatedTime: route.estimatedTime
            )
        }

        guard !quotes.isEmpty else {
            throw SwapError.noRoutes
        }

        return quotes
    }

    /// A split preview never carries an execution: the fee is estimated against the stub deposit and the
    /// order is created in `splitCommit(finalQuote:)` when the user confirms.
    public func splitPreview(
        quote: SplitMultiSwapQuote,
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        recipients: [SplitRecipient],
        slippage: Decimal,
        transactionSettings: TransactionSettings?
    ) async throws -> SplitSwapPreview {
        guard recipients.map(\.percent).reduce(0, +) == 100 else {
            throw SplitSwapError.invalidPercents
        }

        let quoteId = quote.id
        let (assetIn, assetOut) = try assets(tokenIn: tokenIn, tokenOut: tokenOut)

        // /v3/split/preview refuses a body without a refund address (400); fail with a typed error instead.
        // Split routes carry no `addressRules` (no split provider lists ZEC), so a ZEC refund is transparent.
        guard let refundAddress = try await commitRequestBuilder.refundAddress(token: tokenIn, kind: .transparent) else {
            throw SwapError.noRefundAddress
        }

        var request = USwapMultiSwapApi.SplitRequest(
            sellAsset: assetIn,
            sellAmount: amountIn,
            slippage: slippage,
            chainId: commitRequestBuilder.chainId(token: tokenIn),
            outputs: recipients.map { .init(buyAsset: assetOut, percent: $0.percent, destinationAddress: $0.address) }
        )
        request.providerId = quoteId
        request.sourceAddress = try await commitRequestBuilder.sourceAddress(token: tokenIn, policy: .omit, refundAddress: refundAddress)
        request.refundAddress = refundAddress
        request.networkFee = USwapCommitRequestBuilder.networkFee(tokenIn: tokenIn, transactionSettings: transactionSettings)

        let route = try await api.splitPreview(request)

        guard let previewToken = route.previewToken, !previewToken.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        guard route.outputs.allSatisfy({ $0.expectedBuyAmount > 0 }) else {
            throw SplitSwapError.invalidRoute
        }

        try Self.validateSplitOutputs(
            route.outputs.map { ($0.index, $0.destinationAddress) },
            recipients: recipients,
            tokenOut: tokenOut
        )

        guard let stub = route.stubDepositAddress, !stub.isEmpty else {
            throw SwapError.noTransactionData
        }

        let response = USwapMultiSwapApi.SwapResponse(
            expectedBuyAmount: route.expectedBuyAmount,
            minBuyAmount: route.minBuyAmount,
            buyAsset: nil,
            estimatedTime: route.estimatedTime,
            execution: nil,
            uuid: nil,
            approvalSpender: nil
        )
        let destinationAddress = recipients.first?.address ?? ""
        let effectiveSlippage: Decimal? = route.minBuyAmount != nil ? slippage : nil

        let finalQuote = try await finalQuoteFactory.build(
            input: .init(
                tokenIn: tokenIn,
                amountIn: amountIn,
                response: response,
                providerSwapId: nil,
                destinationAddress: destinationAddress,
                slippage: effectiveSlippage,
                recipient: nil,
                transactionSettings: transactionSettings,
                mevProtectionAllowed: false,
                deposit: USwapFinalQuoteFactory.Input.Deposit(address: stub, attachment: nil, isStub: true)
            )
        )

        finalQuote.refundAddress = refundAddress
        finalQuote.minAmountOut = route.minBuyAmount
        finalQuote.providerContext = SplitPreviewContext(
            previewToken: previewToken,
            tokenIn: tokenIn,
            amountIn: amountIn,
            slippage: effectiveSlippage,
            transactionSettings: transactionSettings,
            destinationAddress: destinationAddress,
            refundAddress: refundAddress,
            response: response,
            route: route,
            tokenOut: tokenOut,
            recipients: recipients
        )

        return SplitSwapPreview(quote: finalQuote, outputAmounts: route.outputs.map(\.expectedBuyAmount))
    }

    /// Creates the split order and rebuilds the one transfer against the real deposit. As for a simple
    /// transfer route, the transfer moves the amount the user saw, never the commit's.
    public func splitCommit(finalQuote: SwapFinalQuote) async throws -> SplitSwapCommitment {
        guard let context = finalQuote.providerContext as? SplitPreviewContext else {
            throw SwapError.invalidTransactionData
        }

        // commit has side effects: never create an order from a cancelled task
        try Task.checkCancellation()

        let commit: USwapMultiSwapApi.SplitCommitResponse
        do {
            commit = try await api.splitCommit(.init(previewToken: context.previewToken))
        } catch {
            if error is CancellationError {
                throw error
            }
            throw USwapMultiSwapApi.commitError(networkError: error)
        }

        // the token is consumed: a second slide on the same quote must re-preview, never re-commit
        finalQuote.providerContext = nil

        guard let splitUuid = commit.splitUuid, !splitUuid.isEmpty,
              let execution = commit.execution, execution.isTransfer,
              let instruction = execution.depositInstruction()
        else {
            throw SwapError.invalidTransactionData
        }

        let previewOutputs = context.route.outputs

        // the order must pay exactly the recipients the user confirmed, in the confirmed order
        try Self.validateSplitOutputs(
            commit.outputs.map { ($0.index, $0.destinationAddress) },
            recipients: context.recipients,
            tokenOut: context.tokenOut
        )

        guard commit.outputs.count == previewOutputs.count else {
            throw SplitSwapError.invalidRoute
        }

        var committedAmountOut: Decimal = 0
        for (committed, previewed) in zip(commit.outputs, previewOutputs) {
            guard committed.index == previewed.index, !committed.uuid.isEmpty else {
                throw SplitSwapError.invalidRoute
            }

            // Each output's floor can only hold or improve on what the user confirmed
            if let committedMin = committed.minBuyAmount, let previewedMin = previewed.minBuyAmount, committedMin < previewedMin {
                throw SwapError.invalidTransactionData
            }

            let amountOut = committed.expectedBuyAmount ?? previewed.expectedBuyAmount
            guard amountOut > 0 else {
                throw SplitSwapError.invalidRoute
            }

            committedAmountOut += amountOut
        }

        let committedMinAmountOut: Decimal? = {
            let mins = commit.outputs.compactMap(\.minBuyAmount)
            return mins.count == commit.outputs.count ? mins.reduce(0, +) : context.response.minBuyAmount
        }()

        let response = USwapMultiSwapApi.SwapResponse(
            expectedBuyAmount: committedAmountOut,
            minBuyAmount: committedMinAmountOut,
            buyAsset: nil,
            estimatedTime: context.response.estimatedTime,
            execution: execution,
            uuid: splitUuid,
            approvalSpender: nil,
            expiresAt: commit.expiresAt
        )

        let quote = try await finalQuoteFactory.build(
            input: .init(
                tokenIn: context.tokenIn,
                amountIn: context.amountIn,
                response: response,
                providerSwapId: splitUuid,
                destinationAddress: context.destinationAddress,
                slippage: context.slippage,
                recipient: nil,
                transactionSettings: context.transactionSettings,
                mevProtectionAllowed: false,
                deposit: USwapFinalQuoteFactory.Input.Deposit(address: instruction.address, attachment: instruction.attachment, isStub: false)
            )
        )

        // e.g. the real deposit address needs more than the balance allows
        if let error = quote.transactionError {
            throw error
        }
        guard quote.canSwap else {
            throw SwapError.invalidTransactionData
        }

        quote.refundAddress = context.refundAddress
        quote.minAmountOut = committedMinAmountOut
        quote.setDeposit(address: instruction.address, memo: instruction.attachment?.text)

        return SplitSwapCommitment(quote: quote, splitUuid: splitUuid)
    }

    public func reportSplitInboundTxHash(splitUuid: String, txHash: String) async throws {
        try await api.splitSigned(splitUuid: splitUuid, inboundTxHash: txHash)
    }
}

extension USwapMultiSwapProvider {
    /// What `splitCommit(finalQuote:)` needs from the split preview
    private final class SplitPreviewContext {
        let previewToken: String
        let tokenIn: Token
        let amountIn: Decimal
        let slippage: Decimal?
        let transactionSettings: TransactionSettings?
        let destinationAddress: String
        let refundAddress: String?
        let response: USwapMultiSwapApi.SwapResponse
        let route: USwapMultiSwapApi.SplitRoute
        let tokenOut: Token
        let recipients: [SplitRecipient]

        init(
            previewToken: String,
            tokenIn: Token,
            amountIn: Decimal,
            slippage: Decimal?,
            transactionSettings: TransactionSettings?,
            destinationAddress: String,
            refundAddress: String?,
            response: USwapMultiSwapApi.SwapResponse,
            route: USwapMultiSwapApi.SplitRoute,
            tokenOut: Token,
            recipients: [SplitRecipient]
        ) {
            self.previewToken = previewToken
            self.tokenIn = tokenIn
            self.amountIn = amountIn
            self.slippage = slippage
            self.transactionSettings = transactionSettings
            self.destinationAddress = destinationAddress
            self.refundAddress = refundAddress
            self.response = response
            self.route = route
            self.tokenOut = tokenOut
            self.recipients = recipients
        }
    }

    /// Output `i` must be the request's output `i` (indices exactly 0..<count, as the screen pairs
    /// amounts with recipients by position) and pay recipient `i`'s address. Funds sent to an order
    /// paying anyone else could never be recovered, so a missing or different destination fails.
    private static func validateSplitOutputs(_ outputs: [(index: Int, destinationAddress: String?)], recipients: [SplitRecipient], tokenOut: Token) throws {
        guard outputs.count == recipients.count else {
            throw SplitSwapError.invalidRoute
        }

        // EVM addresses are case-insensitive (checksum casing); other chains compare exactly
        let normalized: (String) -> String = tokenOut.blockchainType.isEvm ? { $0.lowercased() } : { $0 }

        for (position, (output, recipient)) in zip(outputs, recipients).enumerated() {
            guard output.index == position,
                  let destination = output.destinationAddress,
                  normalized(destination) == normalized(recipient.address)
            else {
                throw SplitSwapError.invalidRoute
            }
        }
    }
}

extension USwapMultiSwapProvider {
    /// What `commit(finalQuote:)` needs from the preview: the token to commit and everything the
    /// final-quote factory needs to rebuild a transfer route against the real deposit.
    private final class PreviewContext {
        let previewToken: String
        let venueId: String
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
            venueId: String,
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
            self.venueId = venueId
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

    /// The ZEC destination kind for this quote: the rules' recommendation, forced to transparent for a
    /// vault deposit sold from an OP_RETURN-memo chain. One resolution shared by the recipient check,
    /// the recipient parser filter and the preview request.
    static func destinationKind(quote: MultiSwapQuote, rules: USwapMultiSwapApi.ZcashAddressRules?, tokenIn: Token) -> ZcashAddressKind {
        USwapZcashAddressPolicy.destinationKind(
            rules: rules,
            sellBlockchainType: tokenIn.blockchainType,
            executionType: quote.venue.executionType
        )
    }

    private func assets(tokenIn: Token, tokenOut: Token) throws -> (String, String) {
        guard let assetIn = assetCatalog.asset(token: tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = assetCatalog.asset(token: tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        return (assetIn, assetOut)
    }

    /// A `403 addressBlacklisted` preview surfaces the server's message; anything else passes through.
    private static func previewError(_ error: Error) -> Error {
        if let providerError = USwapMultiSwapApi.providerError(networkError: error), providerError.isAddressBlacklisted {
            return SwapError.addressBlacklisted(message: providerError.message ?? "")
        }

        return error
    }

    /// MEV protection is a property of the route, not the provider: only a server-built signed
    /// transaction on a Merkle-supported same-chain EVM pair can be broadcast through the private RPC.
    private static func mevProtectionAllowed(execution: USwapMultiSwapApi.Execution?, tokenIn: Token, tokenOut: Token) -> Bool {
        guard case .signedTransaction = execution else {
            return false
        }
        return MerkleTransactionAdapter.allowProtection(blockchainTypeIn: tokenIn.blockchainType, blockchainTypeOut: tokenOut.blockchainType)
    }

    enum SwapError: Error, UserFacingError {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noRoutes
        case noRefundAddress
        case noTransactionData
        case invalidTransactionData
        case missingDestinationAddress
        /// The server refused a Zcash address at preview, after the one corrected re-preview; carries its message.
        case previewAddressRejected(message: String)
        /// `403 addressBlacklisted` on preview or commit; carries the server's message.
        case addressBlacklisted(message: String)
        /// An `execution.method` the sell chain's builder cannot follow; nothing is signed.
        case unsupportedInstruction(method: String)
        /// The typed ZEC recipient does not fit the route's destination rule; the user must change it.
        case recipientNotAccepted
        /// A vault deposit from an OP_RETURN-memo chain previewed with a shielded ZEC destination: undeliverable.
        case destinationNotDeliverable
        /// The sender precheck a preview introduced failed: do not send.
        case amlCheckFailed
        /// The sender could not be determined, so the precheck could not run: do not send.
        case amlCheckInconclusive
        /// The backend answered "unprocessed" to the precheck a preview introduced: do not send.
        case amlCheckUnprocessed
        case noZcashAdapter
        case noTonAdapter
        case noStellarAdapter
        case noMoneroAdapter
        case noZanoAdapter
        case noSolanaAdapter
        case noXrpAdapter
        case noTronAdapter
        case noEvmAdapter
        case noNearAdapter

        /// Only the cases that carry text meant for the user; the rest render the generic copy.
        var errorDescription: String? {
            switch self {
            case let .previewAddressRejected(message), let .addressBlacklisted(message):
                return message.isEmpty ? nil : message
            case .unsupportedInstruction:
                return "swap.confirmation.unsupported_instruction".localized
            case .recipientNotAccepted:
                return "swap.confirmation.recipient_not_accepted".localized
            case .destinationNotDeliverable:
                return "swap.confirmation.destination_not_deliverable".localized
            case .amlCheckFailed:
                return "swap.aml.risk.description".localized
            case .amlCheckInconclusive:
                return "swap.aml.inconclusive".localized
            case .amlCheckUnprocessed:
                // not the "continue with risk" text: the confirmation screen offers no way to continue
                return "swap.aml.inconclusive".localized
            default:
                return nil
            }
        }
    }
}
