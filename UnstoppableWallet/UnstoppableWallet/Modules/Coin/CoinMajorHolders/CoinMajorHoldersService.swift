import RxSwift
import RxRelay
import MarketKit

class CoinMajorHoldersService {
    private let coinUid: String
    private let marketKit: Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[TokenHolder]>>()
    private(set) var state: DataStatus<[TokenHolder]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinUid: String, marketKit: Kit) {
        self.coinUid = coinUid
        self.marketKit = marketKit

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.topHoldersSingle(coinUid: coinUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] holders in
                    self?.state = .completed(holders)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinMajorHoldersService {

    var stateObservable: Observable<DataStatus<[TokenHolder]>> {
        stateRelay.asObservable()
    }

    func refresh() {
        sync()
    }

}
