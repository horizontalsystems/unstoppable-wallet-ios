import Foundation

final class PrivateSendOrderCache {
    struct Entry {
        let order: PrivateSendOrder
        let generation: Int
    }

    typealias InitialCommit = () async throws -> PrivateSendOrder
    typealias AdjustedCommit = (PrivateSendOrder, Decimal) async throws -> PrivateSendOrder

    private struct Pending {
        let generation: Int
        let sourceGeneration: Int?
        let task: Task<PrivateSendOrder, Error>
    }

    private let initialCommit: InitialCommit
    private let adjustedCommit: AdjustedCommit
    private let isFresh: (PrivateSendOrder) -> Bool
    private let lock = NSLock()
    private var generation = 0
    private var pending: Pending?

    init(
        initialCommit: @escaping InitialCommit,
        adjustedCommit: @escaping AdjustedCommit,
        isFresh: @escaping (PrivateSendOrder) -> Bool = {
            Date().timeIntervalSince($0.committedAt) < PrivateSendData.quoteLifetime
        }
    ) {
        self.initialCommit = initialCommit
        self.adjustedCommit = adjustedCommit
        self.isFresh = isFresh
    }

    func current() async throws -> Entry {
        while true {
            let pending = withLock { () -> Pending in
                if let pending = self.pending {
                    return pending
                }
                return makeInitialPending()
            }
            let entry = try await resolve(pending)
            guard isFresh(entry.order) else {
                clear(pending)
                continue
            }
            return entry
        }
    }

    func adjusted(from entry: Entry, maximumAmount: Decimal) async throws -> Entry {
        let pending = try withLock { () throws -> Pending in
            // One adjusted commit per source order: a concurrent caller whose own maximum drifted
            // by base units between estimates joins the in-flight commit instead of minting a
            // duplicate provider order.
            if let pending = self.pending, pending.sourceGeneration == entry.generation {
                return pending
            }
            guard self.pending?.generation == entry.generation else { throw PrivateSendError.orderSuperseded }
            return makeAdjustedPending(from: entry, maximumAmount: maximumAmount)
        }
        return try await resolve(pending)
    }
}

private extension PrivateSendOrderCache {
    private func makeInitialPending() -> Pending {
        generation += 1
        let commit = initialCommit
        let pendingGeneration = generation
        let pending = Pending(
            generation: pendingGeneration,
            sourceGeneration: nil,
            task: Task {
                try await commit()
            }
        )
        self.pending = pending
        return pending
    }

    private func makeAdjustedPending(from entry: Entry, maximumAmount: Decimal) -> Pending {
        generation += 1
        let commit = adjustedCommit
        let pending = Pending(
            generation: generation,
            sourceGeneration: entry.generation,
            task: Task { try await commit(entry.order, maximumAmount) }
        )
        self.pending = pending
        return pending
    }

    private func resolve(_ pending: Pending) async throws -> Entry {
        do {
            let order = try await pending.task.value
            return Entry(order: order, generation: pending.generation)
        } catch {
            clear(pending)
            throw error
        }
    }

    private func clear(_ pending: Pending) {
        withLock {
            if self.pending?.generation == pending.generation {
                self.pending = nil
            }
        }
    }

    private func withLock<T>(_ action: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try action()
    }
}
