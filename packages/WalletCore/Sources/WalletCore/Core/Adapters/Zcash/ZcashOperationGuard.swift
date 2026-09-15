import Foundation

// One per process: an adapter recreate must not let an old send and a new node switch miss
// each other. Submissions and engine rebuilds (node switch, stall recovery) are mutually
// exclusive; rewind/wipe/start/stop stay outside, serialised by the SDK's own lifecycle queue.
// Waiters are served in arrival order and give up with `.busy` after `timeout`.
actor ZcashOperationGuard {
    static let shared = ZcashOperationGuard()

    enum Failure: Error {
        case busy
    }

    private var isHeld = false
    private var waiters: [(id: UUID, continuation: CheckedContinuation<Bool, Never>)] = []

    func withSubmission<T>(timeout: TimeInterval, _ body: () async throws -> T) async throws -> T {
        try await run(timeout: timeout, body)
    }

    func withLifecycle<T>(timeout: TimeInterval, _ body: () async throws -> T) async throws -> T {
        try await run(timeout: timeout, body)
    }

    private func run<T>(timeout: TimeInterval, _ body: () async throws -> T) async throws -> T {
        try await acquire(timeout: timeout)
        defer { release() }
        return try await body()
    }

    private func acquire(timeout: TimeInterval) async throws {
        if !isHeld {
            isHeld = true
            return
        }

        let id = UUID()
        let timer = Task { [weak self] in
            try await Task.sleep(seconds: timeout)
            await self?.expire(waiter: id)
        }
        // true = handed the lock by release(), false = timed out
        let acquired = await withCheckedContinuation { continuation in
            waiters.append((id, continuation))
        }
        timer.cancel()

        guard acquired else {
            throw Failure.busy
        }
    }

    private func release() {
        guard !waiters.isEmpty else {
            isHeld = false
            return
        }
        // the lock stays held and passes straight to the first waiter
        waiters.removeFirst().continuation.resume(returning: true)
    }

    private func expire(waiter id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else {
            return
        }
        waiters.remove(at: index).continuation.resume(returning: false)
    }
}
