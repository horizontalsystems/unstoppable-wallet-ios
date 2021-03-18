import RxSwift
import RxRelay
import RxCocoa
import XRatesKit
import CoinKit

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

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinMarketInfo>) {
        loadingRelay.accept(state.isLoading)
    }

}

extension CoinPageViewModel {

    var title: String {
        service.coinCode
    }

    var subtitle: String {
        service.coinTitle
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

}
