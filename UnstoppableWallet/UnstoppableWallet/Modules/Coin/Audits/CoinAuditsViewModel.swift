import RxSwift
import RxRelay
import RxCocoa
import XRatesKit

class CoinAuditsViewModel {
    private let service: CoinAuditsService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: CoinAuditsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
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
                name: auditor.name,
                auditViewItems: auditor.reports.map { auditViewItem(report: $0) }
        )
    }

    private func sync(state: CoinAuditsService.State) {
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .failed:
            stateRelay.accept(.failed)
        case .loaded(let auditors):
            stateRelay.accept(.loaded(viewItems: auditors.map { viewItem(auditor: $0) }))
        }
    }

}

extension CoinAuditsViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

}

extension CoinAuditsViewModel {

    enum State {
        case loading
        case failed
        case loaded(viewItems: [ViewItem])
    }

    struct ViewItem {
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
