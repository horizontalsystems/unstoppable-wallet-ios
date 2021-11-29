import Foundation
import RxSwift
import RxRelay
import MarketKit

class CoinAuditsService {
    private let addresses: [String]
    private let marketKit: Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[Item]>>()
    private(set) var state: DataStatus<[Item]> = .loading {
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
                    self?.handle(auditors: auditors)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private func handle(auditors: [Auditor]) {
        let items = auditors.map { auditor -> Item in
            let sortedReports = auditor.reports.sorted { $0.date > $1.date }

            return Item(
                    logoUrl: auditor.logoUrl,
                    name: auditor.name,
                    latestDate: sortedReports.first?.date ?? Date(timeIntervalSince1970: 0),
                    reports: sortedReports
            )
        }

        state = .completed(items.sorted { $0.latestDate > $1.latestDate })
    }

}

extension CoinAuditsService {

    var stateObservable: Observable<DataStatus<[Item]>> {
        stateRelay.asObservable()
    }

    func refresh() {
        sync()
    }

}

extension CoinAuditsService {

    struct Item {
        let logoUrl: String?
        let name: String
        let latestDate: Date
        let reports: [AuditReport]
    }

}
