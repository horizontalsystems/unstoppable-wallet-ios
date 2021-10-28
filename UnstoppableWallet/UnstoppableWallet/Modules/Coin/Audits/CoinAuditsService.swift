import Foundation
import RxSwift
import RxRelay
import MarketKit

class CoinAuditsService {
    private let addresses: [String]
    private let marketKit: Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[Auditor]>>()
    private(set) var state: DataStatus<[Auditor]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(addresses: [String], marketKit: Kit) {
        self.addresses = addresses
        self.marketKit = marketKit

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.auditReportsSingle(addresses: addresses)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] auditors in
                    self?.state = .completed(auditors)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinAuditsService {

    var stateObservable: Observable<DataStatus<[Auditor]>> {
        stateRelay.asObservable()
    }

    func refresh() {
        sync()
    }

}
