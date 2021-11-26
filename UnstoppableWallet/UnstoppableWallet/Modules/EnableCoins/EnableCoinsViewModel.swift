import RxSwift
import RxRelay
import RxCocoa

class EnableCoinsViewModel {
    private let service: EnableCoinsService
    private let disposeBag = DisposeBag()

    private let hudStateRelay = BehaviorRelay<HudState>(value: .hidden)
    private let confirmationRelay = PublishRelay<String>()

    init(service: EnableCoinsService) {
        self.service = service

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.handle(state: state)
                })
                .disposed(by: disposeBag)

        handle(state: service.state)
    }

    private func handle(state: EnableCoinsService.State) {
        switch state {
        case .idle:
            hudStateRelay.accept(.hidden)
        case .waitingForApprove(let tokenType):
            hudStateRelay.accept(.hidden)
            confirmationRelay.accept(tokenType.title)
        case .loading:
            hudStateRelay.accept(.loading)
        case .success:
            hudStateRelay.accept(.success)
        case .failure:
            hudStateRelay.accept(.error)
        }
    }

}

extension EnableCoinsViewModel {

    var hudStateDriver: Driver<HudState> {
        hudStateRelay.asDriver()
    }

    var confirmationSignal: Signal<String> {
        confirmationRelay.asSignal()
    }

    func onConfirmEnable() {
        service.approveEnable()
    }

}

extension EnableCoinsViewModel {

    enum HudState {
        case hidden
        case loading
        case success
        case error
    }

}
