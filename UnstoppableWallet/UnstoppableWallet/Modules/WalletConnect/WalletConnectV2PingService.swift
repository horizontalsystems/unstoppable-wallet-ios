import Foundation
import RxSwift
import RxRelay
import RxCocoa
import WalletConnect

class WalletConnectV2PingService {
    private static let timeOut: RxTimeInterval = .seconds(10)

    private var disposeBag = DisposeBag()
    private let service: WalletConnectV2Service

    private let stateRelay = BehaviorRelay<WalletConnectMainModule.ConnectionState>(value: .disconnected)
    private(set) var state: WalletConnectMainModule.ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                stateRelay.accept(state)
            }
        }
    }

    init(service: WalletConnectV2Service) {
        self.service = service
    }

    func pingSingle(topic: String) -> Single<()> {
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
        disposeBag = DisposeBag()
    }

}

extension WalletConnectV2PingService {

    var stateObservable: Observable<WalletConnectMainModule.ConnectionState> {
        stateRelay.asObservable()
    }

    func ping(topic: String) {
        clean()

        state = .connecting

        pingSingle(topic: topic)
            .subscribe(onSuccess: { [weak self] in
                self?.state = .connected
            }, onError: { error in
                self.state = .disconnected
            })
            .disposed(by: disposeBag)
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