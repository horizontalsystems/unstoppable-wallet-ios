import RxSwift
import RxRelay
import RxCocoa

protocol IMarketOverviewSectionViewModel {
    var stateObservable: Observable<DataStatus<()>> { get }
    func refresh()
}

class MarketOverviewViewModel {
    private let disposeBag = DisposeBag()

    private let viewModels: [IMarketOverviewSectionViewModel]

    private let successRelay = BehaviorRelay<Bool>(value: false)
    private let loadingRelay = BehaviorRelay<Bool>(value: true)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(viewModels: [IMarketOverviewSectionViewModel]) {
        self.viewModels = viewModels

        subscribe(disposeBag, Observable.combineLatest(viewModels.map { $0.stateObservable })) { [weak self] in
            self?.sync(states: $0)
        }
    }

    private func sync(states: [DataStatus<()>]) {
        var combinedState = DataStatus<()>.completed(())

        for state in states {
            if state.error != nil {
                combinedState = state
                break
            }
            if state.isLoading {
                combinedState = state
                break
            }
        }

        switch combinedState {
        case .loading:
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
            successRelay.accept(false)
        case .completed:
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
            successRelay.accept(true)
        case .failed:
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
            successRelay.accept(false)
        }
    }

}

extension MarketOverviewViewModel {

    var successDriver: Driver<Bool> {
        successRelay.asDriver()
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
