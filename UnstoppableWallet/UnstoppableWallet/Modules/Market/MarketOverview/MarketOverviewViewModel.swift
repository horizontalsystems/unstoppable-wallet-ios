import UIKit
import SectionsTableView
import RxSwift
import RxRelay
import RxCocoa

protocol IMarketOverviewSectionViewModel {
    var stateDriver: Driver<DataStatus<()>> { get }
    func refresh()
}

class MarketOverviewViewModel {
    private let disposeBag = DisposeBag()

    private let viewModels: [IMarketOverviewSectionViewModel]

    private let successRelay = PublishRelay<()>()
    private let loadingRelay = BehaviorRelay<Bool>(value: true)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(viewModels: [IMarketOverviewSectionViewModel]) {
        self.viewModels = viewModels

        viewModels.forEach { viewModel in
            subscribe(disposeBag, viewModel.stateDriver) { [weak self] in
                self?.sync(status: $0)
            }
        }
    }

    private func sync(status: DataStatus<()>) {
        if status.error != nil {
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        } else if status.isLoading {
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        } else {
            successRelay.accept(())
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        }
    }

}

extension MarketOverviewViewModel {

    var successDriver: Driver<()> {
        successRelay.asDriver(onErrorJustReturn: ())
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func refresh() {
        viewModels.forEach { $0.refresh() }
    }

}
