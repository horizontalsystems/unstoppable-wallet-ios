import RxSwift
import RxRelay
import CoinKit
import XRatesKit

class CoinMajorHoldersService {
    private let coinType: CoinType
    private let rateManager: IRateManager
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinType: CoinType, rateManager: IRateManager) {
        self.coinType = coinType
        self.rateManager = rateManager

        rateManager.topTokenHoldersSingle(coinType: coinType, itemsCount: 10)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] holders in
                    self?.state = .loaded(items: holders)
                }, onError: { [weak self] _ in
                    self?.state = .failed
                })
                .disposed(by: disposeBag)
    }

}

extension CoinMajorHoldersService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension CoinMajorHoldersService {

    enum State {
        case loading
        case failed
        case loaded(items: [TokenHolder])
    }

}
