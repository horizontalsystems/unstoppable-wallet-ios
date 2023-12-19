import Combine
import Foundation
import HsToolKit
import RxCocoa
import RxRelay
import RxSwift
import WalletConnectRelay
import WalletConnectSign
import WalletConnectUtils

class WalletConnectSocketConnectionService {
    private static let retryInterval = 10
    private let reachabilityManager: IReachabilityManager
    private let logger: Logger?

    private let disposeBag = DisposeBag()
    private var retryDisposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let statusRelay = PublishRelay<Status>()
    private(set) var status = Status.disconnected {
        didSet {
            logger?.debug("wc v2 change socket status: \(status)")
            statusRelay.accept(status)
        }
    }

    weak var relayClient: RelayClient? {
        didSet {
            updateClient()
        }
    }

    init(reachabilityManager: IReachabilityManager, logger: Logger? = nil) {
        self.reachabilityManager = reachabilityManager
        self.logger = logger

        subscribe(disposeBag, reachabilityManager.reachabilityObservable) { [weak self] isReachable in
            if isReachable {
                self?.retry()
            } else {
                self?.status = .disconnected
            }
        }
    }

    private func sync(status: WalletConnectRelay.SocketConnectionStatus) {
        guard !self.status.equal(to: status) else {
            return
        }

        switch status {
        case .connected:
            self.status = .connected
            retryDisposeBag = DisposeBag()
        case .disconnected:
            self.status = .disconnected
            let retryTimer = Observable.just(()).delay(.seconds(Self.retryInterval), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

            subscribe(retryDisposeBag, retryTimer) { [weak self] in
                self?.retryDisposeBag = DisposeBag()

                self?.retry()
            }
        }
    }

    private func updateClient() {
        cancellables.forEach { cancellable in cancellable.cancel() }
        cancellables.removeAll()

        guard let relayClient else {
            return
        }

        relayClient.socketConnectionStatusPublisher
            .sink { [weak self] status in
                self?.sync(status: status)
            }
            .store(in: &cancellables)
        retry()
    }
}

extension WalletConnectSocketConnectionService {
    func retry() {
        do {
            try relayClient?.connect()
            status = .connecting
        } catch {
            logger?.error("WC v2 can't connect: \(error.localizedDescription)")
        }
    }

    func willEnterForeground() {
        if reachabilityManager.isReachable {
            retry()
        }
    }

    func didEnterBackground() {
        do {
            try relayClient?.disconnect(closeCode: .normalClosure)
            status = .disconnected
        } catch {
            logger?.error("WC v2 can't disconnect socket! \(error.localizedDescription)")
        }
    }

    var statusObservable: Observable<Status> {
        statusRelay.asObservable()
    }
}

extension WalletConnectSocketConnectionService {
    enum Status {
        case disconnected
        case connecting
        case connected

        func equal(to status: WalletConnectRelay.SocketConnectionStatus) -> Bool {
            switch status {
            case .connected: return self == .connected
            case .disconnected: return self == .disconnected
            }
        }
    }
}
