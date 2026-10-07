import Combine
import Foundation
import MarketKit

// Deliberate copy of PrivateSendHandler's orchestration — it is final, typed to PrivateSendPreview,
// and the concurrency-critical parts must not drift under a shared abstraction. The network path:
// /v3/preview (estimated against the stub deposit address, re-run silently while the screen is
// open) -> /v3/commit when the user slides -> build the inner send against the committed deposit
// address through the platform's own IPreSendHandler -> delegate broadcast to the inner handler ->
// report the hash through /v3/signed. The handler never builds a transaction itself.
final class CrossPayHandler {
    typealias DataBuilder = (CrossPayPreview, ISendData, TransactionSettings?, Decimal?) -> CrossPayData

    let baseToken: Token

    private let request: CrossPayRequest
    // Created by CrossPayHandlerProvider for this handler alone; nothing else mutates it.
    private let preSendHandler: IPreSendHandler
    private let service: CrossPayService
    private let swapHistoryManager: SwapHistoryManager
    private let accountManager: AccountManager
    private let dataBuilder: DataBuilder

    private let stateLock = NSLock()
    private var previewTask: Task<CrossPayPreview, Error>?
    private var previewGeneration = 0
    // Everything AFTER the preview is per-call: a settings change racing a refresh gives two
    // concurrent sendData(...) calls, each resolving its own inner handler. Only the newest is
    // allowed to publish, so a superseded handler never becomes the one a later render reads.
    private var syncGeneration = 0
    private var innerHandler: ISendHandler?
    // Tokens already handed to /v3/commit. A consumed preview must never be committed again: the
    // screen re-previews after every commit, but the data a stale slide carries is not refreshed
    // with it.
    private var committedPreviewTokens = Set<String>()

    // Re-entrancy guard: rejects a second concurrent broadcast (double-tap / overlapping send) so
    // the same deposit is never sent twice.
    private var isSending = false

    private let refreshSubject = PassthroughSubject<Void, Never>()

    init(
        request: CrossPayRequest,
        baseToken: Token,
        preSendHandler: IPreSendHandler,
        service: CrossPayService,
        swapHistoryManager: SwapHistoryManager,
        accountManager: AccountManager,
        dataBuilder: @escaping DataBuilder = { CrossPayData(preview: $0, inner: $1, transactionSettings: $2, availableBalance: $3) }
    ) {
        self.request = request
        self.baseToken = baseToken
        self.preSendHandler = preSendHandler
        self.service = service
        self.swapHistoryManager = swapHistoryManager
        self.accountManager = accountManager
        self.dataBuilder = dataBuilder
    }

    // The preview task is unstructured (shared by every concurrent sendData(...) caller), so nothing
    // cancels it for a dismissed screen but this. Not done in discardPreview(): another caller may
    // still be awaiting the shared task there.
    deinit {
        withLock {
            if let previewTask = self.previewTask {
                previewTask.cancel()
            }
        }
    }
}

extension CrossPayHandler: ISendHandler {
    var syncingText: String? { nil }

    var expirationDuration: Int? { Int(CrossPayData.quoteLifetime) }

    // The preview has no side effects (the order is created by `send(data:)` when the user slides),
    // so it is silently re-requested on expiry: the sellAmount under the slide control is always
    // the one the server currently honours.
    var autoRefreshEnabled: Bool { true }

    var initialTransactionSettings: InitialTransactionSettings? { nil }

    // Forwarded lazily: there is no inner handler until the first sendData(...) has previewed a
    // route, and SendView re-reads menuItems on every render, so it fills in afterwards.
    var menuItems: [SendMenuItem] {
        withLock { self.innerHandler }?.menuItems ?? []
    }

    // Fired after a failed or consumed commit: the screen must show a fresh preview, never the one
    // whose token was already spent.
    var refreshPublisher: AnyPublisher<Void, Never>? {
        refreshSubject.eraseToAnyPublisher()
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        // Nothing to preview for an account that can never sign the deposit.
        guard accountManager.activeAccount?.watchAccount != true else {
            throw CrossPayError.commitFailed
        }

        let generation = withLock { () -> Int in
            self.syncGeneration += 1
            return self.syncGeneration
        }

        let preview = try await previewedQuote()

        try Task.checkCancellation()

        // preview.depositAmount, never the entered amount — different quantities in different tokens.
        // Settings come from the request's immutable snapshot, never from a live UI-owned handler.
        // Estimated against the stub with no attachment: the deposit address and its attachment only
        // exist after the commit, and `send(data:)` rebuilds against them.
        let inner = try await innerSendData(
            amount: preview.depositAmount,
            address: preview.stubDepositAddress,
            attachment: nil,
            settings: preview.request.depositSettings,
            transactionSettings: transactionSettings
        ) { innerHandler in
            // Only the newest call publishes its handler. A superseded one is discarded here rather
            // than overwriting `self.innerHandler` with a handler prepared against different
            // TransactionSettings.
            let current = withLock { () -> Bool in
                guard self.syncGeneration == generation else { return false }
                self.innerHandler = innerHandler
                return true
            }

            guard current else { throw CancellationError() }
        }

        try Task.checkCancellation()

        // Re-checked after the estimation await: a newer call may have started (and published) while
        // this one was in flight, and a stale CrossPayData must never reach SendViewModel.sendData.
        guard withLock({ self.syncGeneration == generation }) else { throw CancellationError() }

        // Only the data travels: the handler that broadcasts is rebuilt in send(data:) against the
        // committed deposit address, and menuItems reads the published one off `self`.
        return dataBuilder(preview, inner.data, transactionSettings, preSendHandler.balance)
    }

    func send(data: ISendData) async throws {
        let alreadySending = withLock { () -> Bool in
            if self.isSending { return true }
            self.isSending = true
            return false
        }

        guard !alreadySending else { throw AlreadySendingError() }
        defer { withLock { self.isSending = false } }

        guard let data = data as? CrossPayData else { throw CrossPayError.commitFailed }
        guard let account = accountManager.activeAccount else { throw CrossPayError.commitFailed }

        // Read off the confirmed data, never off `self`: the preview the user saw is the one to commit.
        let preview = data.preview

        // Creates the order. On failure the token is never reused: the reason is toasted and a fresh
        // preview is requested, so the screen simply shows the new quote (no error sheet). The memo
        // is dropped either way — a spent token must never be handed to a later sendData(...).
        let order: CrossPayOrder

        do {
            let fresh = withLock { self.committedPreviewTokens.insert(preview.previewToken).inserted }
            guard fresh else { throw CrossPayError.previewExpired }

            order = try await service.commit(preview: preview)
        } catch is CancellationError {
            // The screen went away mid-commit: the token is still dropped (it may have been spent
            // server-side), but nothing is toasted and no re-preview is requested for it.
            discardPreview()
            throw CommitFailedError(underlying: CancellationError())
        } catch {
            try await failCommit(error: error)
        }

        discardPreview()

        // The real inner send: the committed deposit address, the preview's exact amount and the
        // attachment the chain's handler must carry (one it cannot carry fails the build). Priced with
        // the settings the user confirmed the estimate under. The order exists server-side from here:
        // a send that cannot be built leaves it to expire unfunded and re-previews, like a failed commit.
        let inner: (data: ISendData, handler: ISendHandler)

        do {
            inner = try await innerSendData(
                amount: order.depositAmount,
                address: order.depositAddress,
                attachment: order.attachment,
                settings: order.request.depositSettings,
                transactionSettings: data.transactionSettings
            ) { _ in }

            guard inner.data.canSend, !inner.data.amountAdjusted else {
                throw CrossPayError.commitFailed
            }
        } catch is CancellationError {
            // Same as above: the order is left to expire unfunded, silently.
            discardPreview()
            throw CommitFailedError(underlying: CancellationError())
        } catch {
            try await failCommit(error: error)
        }

        // Pre-saved before broadcasting so the record survives the app dying between the two.
        // isAwaitingTxHash() keeps it out of polling until a txHash lands.
        let uid = UUID().uuidString

        swapHistoryManager.save(swap: Swap(
            uid: uid,
            txHash: nil,
            trackingHandle: uid,
            accountId: account.id,
            providerId: order.providerId,
            status: .notStarted,
            operation: .crossPay,
            tokenIn: order.request.tokenIn,
            tokenOut: order.request.tokenOut,
            amountIn: order.depositAmount,
            amountOut: order.amountOut,
            recipient: order.request.recipient,
            toAddress: order.request.recipient,
            depositAddress: order.depositAddress,
            providerSwapId: order.providerSwapId,
            sourceAddress: nil,
            refundAddress: order.refundAddress,
            estimatedTime: order.estimatedTime,
            date: Date()
        ))

        let ref: String?

        do {
            if let capturing = inner.handler as? ISendHandlerRefCapturing {
                // Every chain the feature runs on yields a ref (TON through the TEP-467 normalized
                // message hash): a txHash makes tracking precise and is what /v3/signed reports.
                ref = try await capturing.sendCapturingRef(data: inner.data)
            } else {
                // A mechanism without a ref (Monero, Zano). The record must not stay behind
                // isAwaitingTxHash() — beginProviderTracking below releases it to
                // providerSwapId-based tracking.
                try await inner.handler.send(data: inner.data)
                ref = nil
            }
        } catch {
            swapHistoryManager.markFailed(trackingHandle: uid)
            // The order is consumed: re-preview so a retry never reuses it (it expires unfunded).
            refreshSubject.send()
            throw error
        }

        // Empty ref = "submitted, id unknown" (Zcash resubmit path) — fall back to provider tracking.
        let txHash = ref.flatMap { $0.isEmpty ? nil : $0 }

        if let txHash {
            swapHistoryManager.resolve(trackingHandle: uid, txHash: txHash)
        } else {
            swapHistoryManager.beginProviderTracking(trackingHandle: uid)
        }

        // Best-effort and off the critical path: funds have moved, so the screen must not wait on
        // the report. The track call carries the hash as a fallback.
        if let txHash {
            let providerSwapId = order.providerSwapId

            Task { [service] in
                do {
                    try await service.reportSigned(uuid: providerSwapId, inboundTxHash: txHash)
                } catch {
                    Core.instance?.logError(message: "cross pay signed report failed: \(error)", save: false)
                }
            }
        }

        // Saved under the DESTINATION chain; the generic save would key on baseToken (ZEC).
        try? Core.shared.recentAddressStorage.save(
            address: order.request.recipient,
            blockchainUid: order.request.tokenOut.blockchainType.uid
        )

        // No wallet auto-add for tokenOut: paying a third party enables nothing for this account.
    }
}

private extension CrossPayHandler {
    func withLock<T>(_ action: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return action()
    }

    // The inner send for a deposit of `amount` to `address`, resolved through the platform's own
    // IPreSendHandler and estimated by the chain's handler. `publish` runs between resolving the
    // handler and estimating with it, so the caller can register (or reject) it.
    func innerSendData(
        amount: Decimal,
        address: String,
        attachment: USwapMultiSwapApi.Attachment?,
        settings: PreSendSettingsSnapshot?,
        transactionSettings: TransactionSettings?,
        publish: (ISendHandler) throws -> Void
    ) async throws -> (data: ISendData, handler: ISendHandler) {
        let result: SendDataResult

        // An attachment the chain's handler cannot carry fails rather than being dropped: a deposit
        // the provider cannot match is typically unrecoverable.
        do {
            result = try preSendHandler.depositSendData(
                amount: amount,
                address: address,
                attachment: attachment,
                settings: settings
            )
        } catch {
            throw CrossPayError.commitFailed
        }

        guard case let .valid(innerSendData) = result else {
            throw CrossPayError.commitFailed
        }

        guard let innerHandler = SendHandlerFactory.handler(sendData: innerSendData) else {
            throw CrossPayError.commitFailed
        }

        // Before any estimation runs: this is what makes the deposit exact. A handler that reduced
        // the amount to fit the balance could drop it below minSellAmount, in which case the deposit
        // is refunded whole and the recipient receives nothing.
        (innerHandler as? IAmountAdjustingSendHandler)?.allowsAmountAdjustment = false

        try Task.checkCancellation()

        try publish(innerHandler)

        let inner = try await innerHandler.sendData(transactionSettings: transactionSettings)

        return (inner, innerHandler)
    }

    // The order could not be created, or could not be funded: the memo is dropped, the reason is
    // toasted, a fresh preview is requested and the send ends with an error the screen does not
    // present (it already shows the new quote).
    func failCommit(error: Error) async throws -> Never {
        discardPreview()

        let message = Self.commitFailureMessage(error)
        await MainActor.run { HudHelper.instance.show(banner: .error(string: message)) }
        refreshSubject.send()

        throw CommitFailedError(underlying: error)
    }

    func discardPreview() {
        withLock { self.previewTask = nil }
    }

    // What the toast says when the order could not be created: the server's discriminator when it
    // names one, a generic line otherwise (server-supplied text is never shown verbatim).
    static func commitFailureMessage(_ error: Error) -> String {
        switch error as? CrossPayError {
        case .rateChanged:
            "swap.confirmation.commit.rate_changed".localized
        case .previewExpired:
            "swap.confirmation.commit.refresh_required".localized
        default:
            "swap.confirmation.commit.failed".localized
        }
    }

    // Previewing is memoised while the preview is alive: sendData(transactionSettings:) is re-invoked
    // on every settings change, and two concurrent callers await the same task rather than each
    // issuing their own request. A preview past its quoteLifetime is discarded and re-requested, as
    // is one whose token was spent by a commit.
    func previewedQuote() async throws -> CrossPayPreview {
        // Two passes at most: a stale memo is cleared exactly once per pass, and a task created
        // after that returns a preview stamped `previewedAt: Date()` — always fresh. A second stale
        // result (a wall-clock jump, a token consumed under the await) ends with previewExpired
        // rather than another request.
        for _ in 0 ..< 2 {
            try Task.checkCancellation()

            let pending: (task: Task<CrossPayPreview, Error>, generation: Int) = withLock {
                if let previewTask = self.previewTask {
                    return (previewTask, self.previewGeneration)
                }

                self.previewGeneration += 1
                let generation = self.previewGeneration
                let request = self.request
                let service = self.service
                let task = Task { try await service.preview(request: request) }
                self.previewTask = task

                return (task, generation)
            }

            let preview: CrossPayPreview

            do {
                // Not cached on `self`: the preview reaches send(data:) on the CrossPayData it
                // produced, so there is no second, unsynchronised copy to disagree with it.
                preview = try await pending.task.value
            } catch {
                // A failed preview is retried on the next refresh. Only clear the memo if it is still
                // the one this call started.
                withLock {
                    if self.previewGeneration == pending.generation {
                        self.previewTask = nil
                    }
                }
                throw error
            }

            let consumed = withLock { self.committedPreviewTokens.contains(preview.previewToken) }

            if !consumed, Date().timeIntervalSince(preview.previewedAt) < CrossPayData.quoteLifetime {
                return preview
            }

            withLock {
                if self.previewGeneration == pending.generation {
                    self.previewTask = nil
                }
            }
        }

        throw CrossPayError.previewExpired
    }
}

extension CrossPayHandler {
    // The order could not be created or funded; the handler already toasted the reason and re-previewed.
    struct CommitFailedError: IHandledSendError {
        let underlying: Error
    }

    // A second broadcast overlapped one in flight; the first is still running, so nothing is shown.
    struct AlreadySendingError: IHandledSendError {
        let underlying = CrossPayError.alreadySending
    }
}
