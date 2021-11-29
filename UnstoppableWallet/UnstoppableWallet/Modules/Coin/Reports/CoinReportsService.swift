import RxSwift
import RxRelay
import MarketKit

class CoinReportsService {
    private let coinUid: String
    private let marketKit: Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[CoinReport]>>()
    private(set) var state: DataStatus<[CoinReport]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinUid: String, marketKit: Kit) {
        self.coinUid = coinUid
        self.marketKit = marketKit

        fetch()
    }

    private func fetch() {
        disposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.coinReportsSingle(coinUid: coinUid)
                .subscribe(onSuccess: { [weak self] reports in
                    self?.state = .completed(reports)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinReportsService {

    var stateObservable: Observable<DataStatus<[CoinReport]>> {
        stateRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

}
