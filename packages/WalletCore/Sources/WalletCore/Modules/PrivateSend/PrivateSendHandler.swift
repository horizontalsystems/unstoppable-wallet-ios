import Combine
import Foundation
import MarketKit

// Where the whole network path lives: /v2/rate -> pick the cheapest confidential route -> /v2/swap ->
// build the inner send through the platform's own IPreSendHandler -> delegate estimation and
// broadcast to the inner handler. The handler never builds a transaction itself.
final class PrivateSendHandler {
    typealias DataBuilder = (PrivateSendOrder, ISendData, ISendHandler) -> PrivateSendData

    let baseToken: Token

    private let preSendHandler: IPreSendHandler
    private let orderCache: PrivateSendOrderCache
    private let swapHistoryManager: SwapHistoryManager
    private let accountManager: AccountManager
    private let dataBuilder: DataBuilder

    private let stateLock = NSLock()
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
        self.baseToken = baseToken
        self.preSendHandler = preSendHandler
        orderCache = PrivateSendOrderCache(
            initialCommit: { try await service.commit(request: request) },
            adjustedCommit: { initialOrder, maximumAmount in
                try await service.commit(
                    request: request,
                    amountIntent: .exactInput(maximumAmount),
                    pinnedProviderId: initialOrder.providerId
                )
            }
        )
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
        let initial = try await orderCache.current()
        try Task.checkCancellation()

        let finalAttempt: PreparedPrivateSendAttempt
        do {
            finalAttempt = try await prepare(order: initial.order, adjustmentPolicy: .report, transactionSettings: transactionSettings)
        } catch let adjustment as SendAmountAdjustmentRequired {
            finalAttempt = try await prepareAdjustedAttempt(
                from: initial,
                maximumAmount: adjustment.maximumAmount,
                transactionSettings: transactionSettings
            )
        }

        try Task.checkCancellation()
        let current = withLock { () -> Bool in
            guard self.syncGeneration == generation else { return false }
            self.innerHandler = finalAttempt.innerHandler
            return true
        }
        guard current else { throw CancellationError() }
        return dataBuilder(finalAttempt.order, finalAttempt.innerData, finalAttempt.innerHandler)
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
    struct PreparedPrivateSendAttempt {
        let order: PrivateSendOrder
        let innerData: ISendData
        let innerHandler: ISendHandler
    }

    func withLock<T>(_ action: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return action()
    }

    func prepare(
        order: PrivateSendOrder,
        adjustmentPolicy: SendAmountAdjustmentPolicy,
        transactionSettings: TransactionSettings?
    ) async throws -> PreparedPrivateSendAttempt {
        let memo = try memoText(for: order)
        let sendData = preSendHandler.sendData(amount: order.depositAmount, address: order.depositAddress, memo: memo)
        guard case let .valid(innerSendData) = sendData else { throw PrivateSendError.innerSendDataUnavailable }
        guard let handler = SendHandlerFactory.handler(sendData: innerSendData) else { throw PrivateSendError.noInnerHandler }
        configure(handler: handler, adjustmentPolicy: adjustmentPolicy)
        try Task.checkCancellation()

        let inner = try await handler.sendData(transactionSettings: transactionSettings)
        return PreparedPrivateSendAttempt(order: order, innerData: inner, innerHandler: handler)
    }

    func prepareAdjustedAttempt(
        from source: PrivateSendOrderCache.Entry,
        maximumAmount: Decimal,
        transactionSettings: TransactionSettings?
    ) async throws -> PreparedPrivateSendAttempt {
        let adjusted = try await orderCache.adjusted(from: source, maximumAmount: maximumAmount)
        try Task.checkCancellation()

        do {
            return try await prepare(order: adjusted.order, adjustmentPolicy: .report, transactionSettings: transactionSettings)
        } catch let adjustment as SendAmountAdjustmentRequired {
            let corrected = try await orderCache.adjusted(from: adjusted, maximumAmount: adjustment.maximumAmount)
            try Task.checkCancellation()
            return try await prepare(order: corrected.order, adjustmentPolicy: .disabled, transactionSettings: transactionSettings)
        }
    }

    func configure(handler: ISendHandler, adjustmentPolicy: SendAmountAdjustmentPolicy) {
        if let handler = handler as? IAmountAdjustmentPolicySendHandler {
            handler.amountAdjustmentPolicy = adjustmentPolicy
        } else if let handler = handler as? IAmountAdjustingSendHandler {
            handler.allowsAmountAdjustment = adjustmentPolicy == .apply
        }
    }

    func memoText(for order: PrivateSendOrder) throws -> String? {
        switch order.attachment {
        case .none:
            return nil
        case let .some(.text(value)):
            guard preSendHandler.memoType(address: order.depositAddress).deliversAttachment else {
                throw PrivateSendError.attachmentUnsupported
            }
            return value
        case .some:
            throw PrivateSendError.attachmentUnsupported
        }
    }
}
