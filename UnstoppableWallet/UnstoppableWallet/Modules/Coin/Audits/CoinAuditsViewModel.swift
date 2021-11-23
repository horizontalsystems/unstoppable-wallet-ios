import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinAuditsViewModel {
    private let service: CoinAuditsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: CoinAuditsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<[Auditor]>) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .completed(let auditors):
            viewItemsRelay.accept(auditors.map { viewItem(auditor: $0) })
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func auditViewItem(report: AuditReport) -> AuditViewItem {
        AuditViewItem(
                date: report.date.map { DateHelper.instance.formatFullDateOnly(from: $0) },
                name: report.name,
                issues: "coin_page.audits.issues".localized + ": \(report.issues)",
                reportUrl: report.link
        )
    }

    private func viewItem(auditor: Auditor) -> ViewItem {
        ViewItem(
                logoUrl: auditor.logoUrl,
                name: auditor.name,
                auditViewItems: auditor.reports.map { auditViewItem(report: $0) }
        )
    }

}

extension CoinAuditsViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension CoinAuditsViewModel {

    struct ViewItem {
        let logoUrl: String
        let name: String
        let auditViewItems: [AuditViewItem]
    }

    struct AuditViewItem {
        let date: String?
        let name: String
        let issues: String
        let reportUrl: String
    }

}
