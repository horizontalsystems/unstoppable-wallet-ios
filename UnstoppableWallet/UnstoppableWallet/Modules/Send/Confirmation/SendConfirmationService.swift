import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import HsToolKit

class SendConfirmationService {
    private var sendDisposeBag = DisposeBag()
    private let sendService: ISendService
    private let logger: Logger
    private let platformCoin: PlatformCoin
    let items: [ISendConfirmationViewItemNew]

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    private(set) var state = State.idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(sendService: ISendService, logger: Logger, platformCoin: PlatformCoin, items: [ISendConfirmationViewItemNew]) {
        self.sendService = sendService
        self.logger = logger
        self.platformCoin = platformCoin
        self.items = items
    }

}

extension SendConfirmationService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var coinName: String {
        platformCoin.name
    }

    func send() {
        sendDisposeBag = DisposeBag()
        let actionLogger = logger.scoped(with: "\(Int.random(in: 0..<1_000_000))")
        actionLogger.debug("Confirm clicked", save: true)

        state = .sending
        sendService
                .sendSingle(logger: actionLogger)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] in
                    actionLogger.debug("Send success", save: true)
                    self?.state = .sent
                }, onError: { [weak self] error in
                    actionLogger.error("Send failed due to \(String(reflecting: error))", save: true)
                    self?.state = .failed(error: error)
                })
                .disposed(by: sendDisposeBag)
    }

}

extension SendConfirmationService {

    enum State {
        case idle
        case sending
        case sent
        case failed(error: Error)
    }

}
