import Combine

class OpenCryptoPayProofWorkerProvider: IAppWorkerProvider {
    private let manager: OpenCryptoPayPaymentManager
    private let submitter: OpenCryptoPaySubmitter
    private let newWorkerSubject = PassthroughSubject<IAppWorker, Never>()

    init(manager: OpenCryptoPayPaymentManager, submitter: OpenCryptoPaySubmitter) {
        self.manager = manager
        self.submitter = submitter
    }

    var newWorkerPublisher: AnyPublisher<IAppWorker, Never> {
        newWorkerSubject.eraseToAnyPublisher()
    }

    func pendingWorkers() -> [IAppWorker] {
        manager.pending().map { worker(record: $0) }
    }

    // Hot path: a freshly transient-failed proof, scheduled while the app runs (registered deferred).
    func schedule(record: OpenCryptoPayPaymentRecord) {
        newWorkerSubject.send(worker(record: record))
    }

    private func worker(record: OpenCryptoPayPaymentRecord) -> OpenCryptoPayProofWorker {
        OpenCryptoPayProofWorker(record: record, manager: manager, submitter: submitter)
    }
}
