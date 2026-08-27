import Combine
import Foundation
import MarketKit

// Where the whole network path lives: /v2/rate -> pick the cheapest confidential route -> /v2/swap ->
// build the inner send through the platform's own IPreSendHandler -> delegate estimation and
// broadcast to the inner handler. The handler never builds a transaction itself.
final class PrivateSendHandler {
    typealias DataBuilder = (PrivateSendOrder, ISendData, ISendHandler) -> PrivateSendData

    let baseToken: Token

    private let request: PrivateSendRequest
    private let preSendHandler: IPreSendHandler
    private let service: PrivateSendService
    private let swapHistoryManager: SwapHistoryManager
    private let accountManager: AccountManager
    private let dataBuilder: DataBuilder

    private let stateLock = NSLock()
    private var commitTask: Task<PrivateSendOrder, Error>?
    private var commitGeneration = 0
    // Everything AFTER the commit is per-call: a settings change racing a refresh gives two
    // concurrent sendData(...) calls, each resolving its own inner handler. Only the newest is
    // allowed to publish, so a superseded handler never becomes the one a later render reads.
    private var syncGeneration = 0
    private var innerHandler: ISendHandler?

    // Re-entrancy guard: rejects a second concurrent broadcast (double-tap / overlapping send) so
    // the same deposit is never sent twice.
    private var isSending = false

    init(
        request: PrivateSendRequest,
        baseToken: Token,
        preSendHandler: IPreSendHandler,
        service: PrivateSendService,
        swapHistoryManager: SwapHistoryManager,
        accountManager: AccountManager,
        dataBuilder: @escaping DataBuilder = { PrivateSendData(order: $0, inner: $1, innerHandler: $2) }
    ) {
        self.request = request
        self.baseToken = baseToken
        self.preSendHandler = preSendHandler
        self.service = service
        self.swapHistoryManager = swapHistoryManager
        self.accountManager = accountManager
        self.dataBuilder = dataBuilder
    }
}

extension PrivateSendHandler: ISendHandler {
    var syncingText: String? { nil }

    // See "Quote expiry": the fee may be re-estimated, but the committed sellAmount ceiling must
    // never be silently swapped under a live slide control.
    var expirationDuration: Int? { Int(PrivateSendData.quoteLifetime) }
    var autoRefreshEnabled: Bool { false }

    // Correct rather than a compromise: the protocol default is nil and EVM/Tron regular sends
    // return nil too. Only ZcashSendHandler (resend) overrides it.
    var initialTransactionSettings: InitialTransactionSettings? { nil }

    // Forwarded lazily: there is no inner handler until the first sendData(...) has committed an
    // order, and SendView re-reads menuItems on every render, so it fills in afterwards.
    var menuItems: [SendMenuItem] {
        withLock { self.innerHandler }?.menuItems ?? []
    }

    var refreshPublisher: AnyPublisher<Void, Never>? { nil }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let generation = withLock { () -> Int in
            self.syncGeneration += 1
            return self.syncGeneration
        }

        let order = try await committedOrder()

        try Task.checkCancellation()

        // Re-evaluated here rather than at handler-resolution time, because the deposit address only
        // exists after the commit.
        let memoText: String?

        switch order.attachment {
        case .none:
            memoText = nil
        case let .some(.text(value)):
            // The same gate the USwap deposit builders apply, through the same predicate — see
            // MemoType.deliversAttachment for why only .onChainPublic is safe here. The handler is
            // asked rather than the chain because it can narrow the answer by address (shielded vs
            // transparent Zcash).
            guard preSendHandler.memoType(address: order.depositAddress).deliversAttachment else {
                throw PrivateSendError.attachmentUnsupported
            }
            memoText = value
        case .some:
            // No SendData case carries a destination tag, and an unknown attachment kind cannot be
            // carried at all.
            throw PrivateSendError.attachmentUnsupported
        }

        // order.depositAmount, never the entered amount: under exact output they are structurally
        // different quantities.
        let result = preSendHandler.sendData(
            amount: order.depositAmount,
            address: order.depositAddress,
            memo: memoText
        )

        guard case let .valid(innerSendData) = result else {
            throw PrivateSendError.innerSendDataUnavailable
        }

        guard let innerHandler = SendHandlerFactory.handler(sendData: innerSendData) else {
            throw PrivateSendError.noInnerHandler
        }

        // Before any estimation runs: this is what makes the deposit exact. A handler that reduced
        // the amount to fit the balance could drop it below minSellAmount, in which case the deposit
        // is refunded whole and the recipient receives nothing.
        (innerHandler as? IAmountAdjustingSendHandler)?.allowsAmountAdjustment = false

        try Task.checkCancellation()

        // Only the newest call publishes its handler. A superseded one is discarded here rather than
        // overwriting `self.innerHandler` with a handler prepared against different
        // TransactionSettings.
        let current = withLock { () -> Bool in
            guard self.syncGeneration == generation else { return false }
            self.innerHandler = innerHandler
            return true
        }

        guard current else { throw CancellationError() }

        let inner = try await innerHandler.sendData(transactionSettings: transactionSettings)

        try Task.checkCancellation()

        // Re-checked after the estimation await: a newer call may have started (and published) while
        // this one was in flight, and a stale PrivateSendData must never reach SendViewModel.sendData.
        guard withLock({ self.syncGeneration == generation }) else { throw CancellationError() }

        // The handler travels WITH the data it produced, so send(data:) broadcasts through exactly
        // the handler that estimated this data rather than whatever self.innerHandler holds later.
        return dataBuilder(order, inner, innerHandler)
    }

    func send(data: ISendData) async throws {
        let alreadySending = withLock { () -> Bool in
            if self.isSending { return true }
            self.isSending = true
            return false
        }

        guard !alreadySending else { throw PrivateSendError.alreadySending }
        defer { withLock { self.isSending = false } }

        guard let data = data as? PrivateSendData else { throw PrivateSendError.invalidData }
        guard let account = accountManager.activeAccount else { throw PrivateSendError.notQuoted }

        // Read off the confirmed data, never off `self`: the order, the inner data and the handler
        // that estimated it are one indivisible triple, and `self.innerHandler` may already belong to
        // a later sync the user never saw.
        let order = data.order
        let innerHandler = data.innerHandler

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
            tokenIn: order.request.token,
            tokenOut: order.request.token,
            amountIn: order.depositAmount,
            amountOut: order.amountOut,
            recipient: order.request.recipient,
            toAddress: order.request.recipient,
            depositAddress: order.depositAddress,
            providerSwapId: order.providerSwapId,
            sourceAddress: nil,
            refundAddress: order.refundAddress,
            date: Date()
        ))

        let ref: String?

        do {
            if let capturing = innerHandler as? ISendHandlerRefCapturing {
                ref = try await capturing.sendCapturingRef(data: data.inner)
            } else {
                // A mechanism that can never yield a ref (TonKit's send returns Void). The record
                // must not stay behind isAwaitingTxHash() — beginProviderTracking below releases it
                // to providerSwapId-based tracking. Handlers whose mechanism does yield a ref should
                // conform to ISendHandlerRefCapturing instead: a txHash makes tracking precise.
                try await innerHandler.send(data: data.inner)
                ref = nil
            }
        } catch {
            swapHistoryManager.markFailed(trackingHandle: uid)
            throw error
        }

        if let ref {
            swapHistoryManager.resolve(trackingHandle: uid, txHash: ref)
        } else {
            swapHistoryManager.beginProviderTracking(trackingHandle: uid)
        }

        // Deliberately no wallet auto-add for tokenOut (unlike a swap): tokenOut == tokenIn.
    }
}

private extension PrivateSendHandler {
    func withLock<T>(_ action: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return action()
    }

    // Committing is memoised while the order is alive, and the memo is mandatory rather than an
    // optimisation: sendData(transactionSettings:) is re-invoked on every settings change, and each
    // /v2/swap creates a REAL order. Two concurrent callers await the same task rather than each
    // issuing their own commit. An order past its quoteLifetime is discarded and re-committed — the
    // "Refresh" the UI shows at expiry must produce a fresh order, not re-serve one the provider no
    // longer honours.
    func committedOrder() async throws -> PrivateSendOrder {
        // The loop terminates: a stale memo is cleared exactly once per iteration, and a task
        // created after that returns an order stamped `committedAt: Date()` — always fresh.
        while true {
            let pending: (task: Task<PrivateSendOrder, Error>, generation: Int) = withLock {
                if let commitTask = self.commitTask {
                    return (commitTask, self.commitGeneration)
                }

                self.commitGeneration += 1
                let generation = self.commitGeneration
                let request = self.request
                let service = self.service
                let task = Task { try await service.commit(request: request) }
                self.commitTask = task

                return (task, generation)
            }

            let order: PrivateSendOrder

            do {
                // Not cached on `self`: the order reaches send(data:) on the PrivateSendData it
                // produced, so there is no second, unsynchronised copy to disagree with it.
                order = try await pending.task.value
            } catch {
                // A failed commit created no order, so a refresh is allowed to retry. Only clear
                // the memo if it is still the one this call started.
                withLock {
                    if self.commitGeneration == pending.generation {
                        self.commitTask = nil
                    }
                }
                throw error
            }

            if Date().timeIntervalSince(order.committedAt) < PrivateSendData.quoteLifetime {
                return order
            }

            withLock {
                if self.commitGeneration == pending.generation {
                    self.commitTask = nil
                }
            }
        }
    }
}
