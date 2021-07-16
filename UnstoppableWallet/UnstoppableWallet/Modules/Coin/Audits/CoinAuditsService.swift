import Foundation
import RxSwift
import RxRelay
import CoinKit
import XRatesKit

class CoinAuditsService {
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

        rateManager.auditReportsSingle(coinType: coinType)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] auditors in
                    self?.state = .loaded(auditors: auditors)
                }, onError: { [weak self] _ in
                    self?.state = .failed
                })
                .disposed(by: disposeBag)
    }

}

extension CoinAuditsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension CoinAuditsService {

    enum State {
        case loading
        case failed
        case loaded(auditors: [Auditor])
    }

}
