import Combine
import Foundation

// Zcash re-check signal: arms a debounce on .notSynced of the live adapter, disarms on
// recovery, keeps firing with backoff while the stall persists; re-attaches on adapter rebuild.
class ZcashNodeUpdateSignalProvider {
    private static let debounceInterval: TimeInterval = 15
    private static let initialRetryInterval: TimeInterval = 60
    private static let maxRetryInterval: TimeInterval = 900

    private let updateSignalSubject = PassthroughSubject<Void, Never>()

    private var adapterDataCancellables: [AnyCancellable] = []
    private var adapterCancellables: [AnyCancellable] = []

    private let queue = DispatchQueue(label: "\(AppConfig.label).zcash-node-update-signal", qos: .utility)

    // queue-confined
    private var stalled = false
    private var pendingWorkItem: DispatchWorkItem?
    private var retryInterval: TimeInterval = ZcashNodeUpdateSignalProvider.initialRetryInterval

    private var cancellables: [AnyCancellable] = []

    init(adapterManager: AdapterManager) {
        adapterManager.adapterDataReadyPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] adapterData in
                self?.attach(adapterData: adapterData)
            }
            .store(in: &adapterDataCancellables)
    }

    // Foreground return resets the backoff. Deferred to the first adapter event: this provider
    // is built during Core's own init, when Core.shared is not yet available.
    private func subscribeToForegroundIfNeeded() {
        guard cancellables.isEmpty else { return }

        Core.shared.appManager.didBecomeActivePublisher
            .sink { [weak self] in
                self?.queue.async { [weak self] in
                    guard let self else { return }
                    retryInterval = Self.initialRetryInterval
                }
            }
            .store(in: &cancellables)
    }

    private func attach(adapterData: AdapterManager.AdapterData) {
        subscribeToForegroundIfNeeded()

        // adapter set rebuilt (account switch, rescan): drop the old subscription and state
        adapterCancellables = []
        queue.async { [weak self] in self?.reset() }

        let zcashAdapter = adapterData.adapterMap.first { wallet, _ in wallet.token.blockchainType == .zcash }?.value as? ZcashAdapter
        guard let zcashAdapter else { return }

        zcashAdapter.balanceStateUpdatedPublisher
            .sink { [weak self] state in
                self?.queue.async { [weak self] in self?.handle(state: state) }
            }
            .store(in: &adapterCancellables)
    }

    private func handle(state: AdapterState) {
        switch state {
        case .notSynced:
            guard !stalled else { return }
            stalled = true
            schedule(after: Self.debounceInterval)
        default:
            reset()
        }
    }

    private func schedule(after interval: TimeInterval) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.fireIfStillStalled() }
        pendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    private func fireIfStillStalled() {
        guard stalled else { return }

        updateSignalSubject.send()

        schedule(after: retryInterval)
        retryInterval = min(retryInterval * 2, Self.maxRetryInterval)
    }

    private func reset() {
        stalled = false
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
        retryInterval = Self.initialRetryInterval
    }
}

extension ZcashNodeUpdateSignalProvider: IUpdateSignalProvider {
    var updateSignalPublisher: AnyPublisher<Void, Never> {
        updateSignalSubject.eraseToAnyPublisher()
    }
}
