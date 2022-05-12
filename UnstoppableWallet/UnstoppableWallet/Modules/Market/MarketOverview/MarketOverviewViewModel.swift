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

        subscribe(disposeBag, Driver.zip(viewModels.map { $0.stateDriver })) { [weak self] in
            self?.sync(statuses: $0)
        }
    }

    private func sync(statuses: [DataStatus<()>]) {
        var status = DataStatus<()>.completed(())
        statuses.forEach {
            if case .failed = $0 {
                status = $0
                return
            }
            if case .loading = $0 {
                status = $0
                return
            }
        }

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
