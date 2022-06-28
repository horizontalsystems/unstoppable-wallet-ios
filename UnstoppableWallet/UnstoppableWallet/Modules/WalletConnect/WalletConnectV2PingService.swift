import Foundation
import RxSwift
import RxRelay
import RxCocoa
import HsToolKit

class WalletConnectV2PingService {
    private static let timeOut: RxTimeInterval = .seconds(10)

    private let disposeBag = DisposeBag()
    private var pingDisposeBag = DisposeBag()
    private let service: WalletConnectV2Service
    private let socketConnectionService: WalletConnectV2SocketConnectionService
    private let logger: Logger?

    private let stateRelay = BehaviorRelay<WalletConnectMainModule.ConnectionState>(value: .disconnected)
    private(set) var state: WalletConnectMainModule.ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                logger?.debug("WC v2 PingService change state to: \(state)")
                stateRelay.accept(state)
            }
        }
    }

    var topic: String?

    init(service: WalletConnectV2Service, socketConnectionService: WalletConnectV2SocketConnectionService, logger: Logger? = nil) {
        self.service = service
        self.socketConnectionService = socketConnectionService
        self.logger = logger

        subscribe(disposeBag, socketConnectionService.statusObservable) { [weak self] in self?.sync(connectionStatus: $0) }
    }

    private func pingSingle(topic: String) -> Single<()> {
        Single.create { [weak self] observer in
            if self?.service == nil {
                observer(.error(ConnectionError.noService))
            }

            self?.service.ping(topic: topic, completion: { result in
                switch result {
                case .success: observer(.success(()))
                case .failure(let error): observer(.error(error))
                }
            })

            return Disposables.create()
        }.timeout(Self.timeOut, scheduler: ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
    }

    private func clean() {
        pingDisposeBag = DisposeBag()
    }

    private func sync(connectionStatus: WalletConnectV2SocketConnectionService.Status? = nil, state: WalletConnectMainModule.ConnectionState? = nil) {
        let connectionStatus = connectionStatus ?? socketConnectionService.status
        let state = state ?? self.state

        logger?.debug("WC v2 PingService use: connection: \(connectionStatus) + ping: \(state)")
        switch connectionStatus {
        case .disconnected: self.state = .disconnected
        case .connecting: self.state = .connecting
        case .connected: self.state = state
        }
    }

}

extension WalletConnectV2PingService {

    var stateObservable: Observable<WalletConnectMainModule.ConnectionState> {
        stateRelay.asObservable()
    }

    func ping() {
        guard let topic = topic else {
            logger?.error("WC v2 PingService topic not set!")
            return
        }

        clean()
        sync(state: .connecting)

        pingSingle(topic: topic)
            .subscribe(onSuccess: { [weak self] in
                self?.sync(state: .connected)
            }, onError: { [weak self] error in
                self?.logger?.error("WC v2 PingService cant ping topic: \(self?.topic ?? "N/A")")
                self?.sync(state: .disconnected)
            })
            .disposed(by: pingDisposeBag)
    }

    func receiveResponse() {
        clean()
        state = .connected
    }

    func disconnect() {
        clean()
        state = .disconnected
    }

}

extension WalletConnectV2PingService {

    enum ConnectionError: Error {
    case noService
    case timeout
    }

}