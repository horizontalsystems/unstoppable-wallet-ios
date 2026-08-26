import Combine
import Foundation
import HsToolKit

// Generic "time to re-check the node" signal; the conforming class encapsulates its own
// source composition (sync state, foreground, ...) so new sources never grow this contract.
protocol IUpdateSignalProvider: AnyObject {
    var updateSignalPublisher: AnyPublisher<Void, Never> { get }
}

// Chain-side operations behind the seam (analog: ZcashMigrator ↔ IZcashMigrationEngine);
// pingNodes() returns ONLY auto-select candidates — validity/eligibility are the chain's job.
protocol INodeAutoSelectEngine: AnyObject {
    var autoSelectEnabled: Bool { get }
    var currentNodeId: String { get }
    func pingNodes() async -> [NodeAutoSelector.PingResult]
    func switchNode(id: String) async throws
}

// App-scoped orchestrator: fire → single-flight → probe → policy → switch; pacing lives in
// the signal provider, and a nil provider degrades the chain to startup-only auto-select.
class NodeAutoSelector {
    struct PingResult {
        let id: String
        let responseTime: TimeInterval
        let height: UInt64
    }

    // Nodes lagging more than this many blocks behind the best-known tip are never
    // auto-selected, no matter how fast they respond.
    private static let heightLagThreshold: UInt64 = 10
    // Only switch away from a working current node when the winner is meaningfully faster,
    // so repeated pings don't flip-flop nodes over noise.
    private static let switchLatencyGain: TimeInterval = 0.1

    private let engine: INodeAutoSelectEngine
    private let reachabilityManager: ReachabilityManager
    private var cancellables: [AnyCancellable] = []

    private let lock = NSLock()
    private var probeInFlight = false

    init(engine: INodeAutoSelectEngine, updateSignalProvider: IUpdateSignalProvider?, reachabilityManager: ReachabilityManager) {
        self.engine = engine
        self.reachabilityManager = reachabilityManager

        updateSignalProvider?.updateSignalPublisher
            .sink { [weak self] in
                Task { [weak self] in
                    await self?.probeAndSwitch()
                }
            }
            .store(in: &cancellables)
    }

    // Picks the fastest of the candidates that are not lagging behind the best-known tip.
    // Returns nil when the current node should be kept (hysteresis) or no candidate qualifies.
    static func fastestNodeId(results: [PingResult], currentId: String) -> String? {
        guard let maxHeight = results.map(\.height).max() else { return nil }

        // Subtraction, not `height + threshold`: a height near UInt64.max would trap the
        // addition; maxHeight is the candidate maximum, so the difference cannot underflow.
        let fresh = results.filter { maxHeight - $0.height <= heightLagThreshold }

        guard let fastest = fresh.min(by: { $0.responseTime < $1.responseTime }) else { return nil }

        guard fastest.id != currentId else { return nil }

        if let current = fresh.first(where: { $0.id == currentId }),
           current.responseTime <= fastest.responseTime + Self.switchLatencyGain
        {
            return nil
        }

        return fastest.id
    }

    func autoSelectFastestNodeOnStartup() async {
        await probeAndSwitch()
    }

    private func probeAndSwitch() async {
        guard engine.autoSelectEnabled, reachabilityManager.isReachable else { return }
        guard beginProbe() else { return }
        defer { endProbe() }

        // Snapshot before the probe: a manual selection landing mid-probe makes the result
        // stale — manual wins over auto, the probe outcome is discarded.
        let nodeIdBeforeProbe = engine.currentNodeId

        let results = await engine.pingNodes()

        guard engine.currentNodeId == nodeIdBeforeProbe else { return }
        guard let winner = Self.fastestNodeId(results: results, currentId: nodeIdBeforeProbe) else { return }

        // A throw is a chain gate refusing right now (e.g. send in progress) — no retry here,
        // the next update signal or startup probe tries again.
        try? await engine.switchNode(id: winner)
    }

    private func beginProbe() -> Bool {
        lock.withLock {
            guard !probeInFlight else { return false }
            probeInFlight = true
            return true
        }
    }

    private func endProbe() {
        lock.withLock { probeInFlight = false }
    }
}
