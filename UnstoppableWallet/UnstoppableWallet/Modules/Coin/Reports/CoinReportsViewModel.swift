import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinReportsViewModel {
    private let service: CoinReportsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: CoinReportsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<[CoinReport]>) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .completed(let reports):
            viewItemsRelay.accept(reports.map { viewItem(report: $0) })
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func viewItem(report: CoinReport) -> ViewItem {
        ViewItem(
                author: report.author,
                title: report.title,
                body: report.body,
                date: DateHelper.instance.formatMonthYear(from: report.date),
                url: report.url
        )
    }

}

extension CoinReportsViewModel {

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

extension CoinReportsViewModel {

    struct ViewItem {
        let author: String
        let title: String
        let body: String
        let date: String
        let url: String
    }

}
