import Combine
import Foundation

protocol IAppWorker: AnyObject {
    var id: String { get } // dedupe key (e.g. txHash)
    var interval: TimeInterval { get } // own retry period
    func run() async -> Bool // true = work done → stop & remove; false = retry after interval
}

protocol IAppWorkerProvider: AnyObject {
    func pendingWorkers() -> [IAppWorker] // pull: unfinished work on start / each foreground
    var newWorkerPublisher: AnyPublisher<IAppWorker, Never> { get } // push: appears during the session
}

// Serializes every worker.run() so per-worker timers may overlap but network calls never fire in parallel.
private actor AppWorkerRunner {
    func run(_ worker: IAppWorker) async -> Bool {
        await worker.run()
    }
}

class AppWorkerRegistry {
    private var providers: [IAppWorkerProvider] = []
    private var tasks: [String: Task<Void, Never>] = [:] // worker.id → its retry loop
    private var cancellables = Set<AnyCancellable>()
    private let runner = AppWorkerRunner()

    init(appManager: AppManager) {
        appManager.didBecomeActivePublisher
            .sink { [weak self] in self?.bootstrap() }
            .store(in: &cancellables)
        appManager.didEnterBackgroundPublisher
            .sink { [weak self] in self?.cancelAll() }
            .store(in: &cancellables)
    }

    func register(provider: IAppWorkerProvider) {
        providers.append(provider)
        provider.newWorkerPublisher
            .sink { [weak self] worker in self?.add(worker, deferred: true) }
            .store(in: &cancellables)
    }

    // Start + every foreground: (re)create workers for whatever is still unfinished.
    private func bootstrap() {
        for worker in providers.flatMap({ $0.pendingWorkers() }) {
            add(worker, deferred: false)
        }
    }

    private func add(_ worker: IAppWorker, deferred: Bool) {
        Task { @MainActor [weak self] in self?.addOnMain(worker, deferred: deferred) }
    }

    @MainActor
    private func addOnMain(_ worker: IAppWorker, deferred: Bool) {
        guard tasks[worker.id] == nil else { return } // dedupe by id
        let interval = worker.interval
        let id = worker.id
        // Task retains the worker strongly (nothing else does); self stays weak to avoid a registry↔task cycle.
        tasks[id] = Task { [weak self] in
            if deferred {
                try? await Task.sleep(seconds: interval)
            }
            while !Task.isCancelled {
                guard let self else { break }
                let done = await runner.run(worker)
                if done { break }
                try? await Task.sleep(seconds: interval)
            }
            // self-remove only on natural finish; cancelAll already cleared the map.
            if !Task.isCancelled {
                self?.tasks[id] = nil
            }
        }
    }

    private func cancelAll() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            tasks.values.forEach { $0.cancel() }
            tasks.removeAll()
        }
    }
}
