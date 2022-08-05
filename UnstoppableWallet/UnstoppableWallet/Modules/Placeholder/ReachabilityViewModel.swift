import HsToolKit
import RxSwift
import RxCocoa
import RxRelay

class ReachabilityViewModel {
    private let disposeBag = DisposeBag()

    private let service: ReachabilityService

    private let retryRelay = PublishRelay<()>()

    init(service: ReachabilityService) {
        self.service = service

        service.reachabilityObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] reachable in
                    if reachable {
                        self?.retryRelay.accept(())
                    }
                })
                .disposed(by: disposeBag)
    }

    var isReachable: Bool {
        service.isReachable
    }

    var retryDriver: Driver<()> {
        retryRelay.asDriver(onErrorJustReturn: ())
    }

}
