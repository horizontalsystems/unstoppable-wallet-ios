import Combine
import Foundation
import MarketKit

// Deliberate copy of PrivateSendHandler's orchestration — it is final, typed to PrivateSendOrder,
// and the concurrency-critical parts must not drift under a shared abstraction.
final class CrossPayHandler {
    typealias DataBuilder = (CrossPayOrder, ISendData, ISendHandler, Decimal?) -> CrossPayData

    let baseToken: Token

    private let request: CrossPayRequest
    private let preSendHandler: IPreSendHandler
    private let service: CrossPayService
    private let swapHistoryManager: SwapHistoryManager
    private let accountManager: AccountManager
    private let dataBuilder: DataBuilder

    private let stateLock = NSLock()
    private var commitTask: Task<CrossPayOrder, Error>?
    private var commitGeneration = 0
    // A refresh racing a re-sync gives two concurrent sendData calls; only the newest may publish
    // its inner handler.
    private var syncGeneration = 0
    private var innerHandler: ISendHandler?

    // Re-entrancy guard: the same deposit must never be sent twice.
    private var isSending = false

    // A retried broadcast reuses the row it failed on; only a new order starts a new row.
    private var savedRecordUids = [String: String]()

    init(
        request: CrossPayRequest,
        baseToken: Token,
        preSendHandler: IPreSendHandler,
        service: CrossPayService,
        swapHistoryManager: SwapHistoryManager,
        accountManager: AccountManager,
        dataBuilder: @escaping DataBuilder = { CrossPayData(order: $0, inner: $1, innerHandler: $2, availableBalance: $3) }
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

extension CrossPayHandler: ISendHandler {
    var syncingText: String? { nil }

    // Past the order's lifetime the screen offers Refresh, which commits a fresh order.
    var expirationDuration: Int? { Int(CrossPayData.quoteLifetime) }
    var autoRefreshEnabled: Bool { false }

    var initialTransactionSettings: InitialTransactionSettings? { nil }

    // No inner handler until the first sendData commits; SendView re-reads this on every render.
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

        // Re-evaluated here: the deposit address only exists after the commit.
        let memoText: String?

        switch order.attachment {
        case .none:
            memoText = nil
        case let .some(.text(value)):
            // A deposit the provider cannot match by memo is typically unrecoverable — an
            // undeliverable memo fails rather than being dropped.
            guard preSendHandler.memoType(address: order.depositAddress).deliversAttachment else {
                throw CrossPayError.commitFailed
            }
            memoText = value
        case .some:
            // No send path carries an unknown attachment kind.
            throw CrossPayError.commitFailed
        }

        // The deposit, never the entered amount — different quantities in different tokens.
        let result = preSendHandler.sendData(
            amount: order.depositAmount,
            address: order.depositAddress,
            memo: memoText
        )

        guard case let .valid(innerSendData) = result else {
            throw CrossPayError.commitFailed
        }

        guard let innerHandler = SendHandlerFactory.handler(sendData: innerSendData) else {
            throw CrossPayError.commitFailed
        }

        // An auto-reduced deposit could drop below minSellAmount: refunded whole, recipient gets nothing.
        (innerHandler as? IAmountAdjustingSendHandler)?.allowsAmountAdjustment = false

        try Task.checkCancellation()

        // Only the newest call publishes its handler.
        let current = withLock { () -> Bool in
            guard self.syncGeneration == generation else { return false }
            self.innerHandler = innerHandler
            return true
        }

        guard current else { throw CancellationError() }

        let inner = try await innerHandler.sendData(transactionSettings: transactionSettings)

        try Task.checkCancellation()

        // Re-checked after the await: stale CrossPayData must never reach SendViewModel.
        guard withLock({ self.syncGeneration == generation }) else { throw CancellationError() }

        // The handler travels WITH its data so send(data:) broadcasts through the one that estimated it.
        return dataBuilder(order, inner, innerHandler, preSendHandler.balance)
    }

    func send(data: ISendData) async throws {
        let alreadySending = withLock { () -> Bool in
            if self.isSending { return true }
            self.isSending = true
            return false
        }

        guard !alreadySending else { throw CrossPayError.commitFailed }
        defer { withLock { self.isSending = false } }

        guard let data = data as? CrossPayData else { throw CrossPayError.commitFailed }
        guard let account = accountManager.activeAccount else { throw CrossPayError.commitFailed }

        // Read off the confirmed data, never off `self` — the triple is indivisible.
        let order = data.order
        let innerHandler = data.innerHandler

        // Pre-saved so the record survives the app dying mid-broadcast; a failed retry reuses its row.
        let uid: String
        let previousUid = withLock { savedRecordUids[order.providerSwapId] }

        if let previousUid, swapHistoryManager.retryFailed(trackingHandle: previousUid) {
            uid = previousUid
        } else {
            uid = UUID().uuidString
            withLock { savedRecordUids[order.providerSwapId] = uid }

            swapHistoryManager.save(swap: Swap(
                uid: uid,
                txHash: nil,
                trackingHandle: uid,
                accountId: account.id,
                providerId: order.providerId,
                status: .notStarted,
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
                date: Date()
            ))
        }

        let ref: String?

        do {
            if let capturing = innerHandler as? ISendHandlerRefCapturing {
                ref = try await capturing.sendCapturingRef(data: data.inner)
            } else {
                try await innerHandler.send(data: data.inner)
                ref = nil
            }
        } catch {
            swapHistoryManager.markFailed(trackingHandle: uid)
            throw error
        }

        // Empty ref = "submitted, id unknown" (Zcash resubmit path) — fall back to provider tracking.
        if let ref, !ref.isEmpty {
            swapHistoryManager.resolve(trackingHandle: uid, txHash: ref)
        } else {
            swapHistoryManager.beginProviderTracking(trackingHandle: uid)
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

    // Memoised while the order is alive — each /v2/swap creates a REAL order, so concurrent callers
    // await one task. An expired order is discarded and re-committed.
    func committedOrder() async throws -> CrossPayOrder {
        // Terminates: a fresh task returns an order stamped with a fresh committedAt.
        while true {
            let pending: (task: Task<CrossPayOrder, Error>, generation: Int) = withLock {
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

            let order: CrossPayOrder

            do {
                order = try await pending.task.value
            } catch {
                // A failed commit created no order — clear the memo (if still ours) so refresh can retry.
                withLock {
                    if self.commitGeneration == pending.generation {
                        self.commitTask = nil
                    }
                }
                throw error
            }

            if Date().timeIntervalSince(order.committedAt) < CrossPayData.quoteLifetime {
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
