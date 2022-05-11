import UIKit
import SectionsTableView
import RxSwift
import RxRelay
import RxCocoa

protocol IMarketOverviewDataSource {
    var presentDelegate: IPresentDelegate { get set }
    var tableView: UITableView? { get set }
    var status: DataStatus<[SectionProtocol]> { get }
    var updateDriver: Driver<()> { get }

    func refresh()
}

class MarketOverviewViewModel {
    private let disposeBag = DisposeBag()

    private let dataSources: [IMarketOverviewDataSource]

    private let sectionsRelay = BehaviorRelay<[SectionProtocol]>(value: [])
    private let loadingRelay = BehaviorRelay<Bool>(value: true)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(dataSources: [IMarketOverviewDataSource]) {
        self.dataSources = dataSources

        dataSources.forEach { dataSource in
            subscribe(disposeBag, dataSource.updateDriver) { [weak self] in
                self?.sync()
            }
        }
    }

    private func sync() {
        if showError {
            sectionsRelay.accept([])
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        } else if isLoading {
            sectionsRelay.accept([])
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        } else {
            sectionsRelay.accept(sections)
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        }
    }

    private var isLoading: Bool {
        dataSources.first { $0.status.isLoading } != nil
    }

    private var showError: Bool {
        dataSources.first { $0.status.error != nil } != nil
    }

    private var sections: [SectionProtocol] {
        var sections = [SectionProtocol]()
        dataSources.forEach { source in
            sections.append(contentsOf: source.status.data ?? [])
        }
        return sections
    }

}

extension MarketOverviewViewModel {

    var sectionsDriver: Driver<[SectionProtocol]> {
        sectionsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func refresh() {
        dataSources.forEach { $0.refresh() }
    }

}
