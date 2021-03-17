import RxSwift
import RxRelay
import RxCocoa
import XRatesKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)

    init(service: CoinPageService) {
        self.service = service

//        CoinPageService.stateObservable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//                .subscribe(onNext: { [weak self] state in
//                    self?.sync(state: state)
//                })
//                .disposed(by: disposeBag)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinMarketInfo>) {

    }

}
