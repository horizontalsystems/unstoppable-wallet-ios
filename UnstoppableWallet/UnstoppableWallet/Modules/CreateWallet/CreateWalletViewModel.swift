import RxSwift
import RxRelay
import RxCocoa
import CoinKit

class CreateWalletViewModel {
    private let service: CreateWalletService

    private let disposeBag = DisposeBag()
    private let viewStateRelay = BehaviorRelay<CoinToggleViewModel.ViewState>(value: .empty)
    private let errorRelay = PublishRelay<Error>()
    private let enableFailedRelay = PublishRelay<Coin>()
    private let finishRelay = PublishRelay<Void>()

    private var filter: String?

    init(service: CreateWalletService) {
        self.service = service

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.syncViewState(state: state)
                })
                .disposed(by: disposeBag)

        syncViewState()
    }

    private func viewItem(item: CreateWalletService.Item) -> CoinToggleViewModel.ViewItem {
        CoinToggleViewModel.ViewItem(
                coin: item.coin,
                state: .toggleVisible(enabled: item.enabled)
        )
    }

    private func filtered(items: [CreateWalletService.Item]) -> [CreateWalletService.Item] {
        guard let filter = filter else {
            return items
        }

        return items.filter { item in
            item.coin.title.localizedCaseInsensitiveContains(filter) || item.coin.code.localizedCaseInsensitiveContains(filter)
        }
    }

    private func syncViewState(state: CreateWalletService.State? = nil) {
        let state = state ?? service.state

        let viewState = CoinToggleViewModel.ViewState(
                featuredViewItems: filtered(items: state.featuredItems).map {
                    viewItem(item: $0)
                },
                viewItems: filtered(items: state.items).map {
                    viewItem(item: $0)
                }
        )

        viewStateRelay.accept(viewState)
    }

}

extension CreateWalletViewModel: ICoinToggleViewModel {

    var viewStateDriver: Driver<CoinToggleViewModel.ViewState> {
        viewStateRelay.asDriver()
    }

    func onEnable(coin: Coin) {
        do {
            try service.enable(coin: coin)
        } catch {
            errorRelay.accept(error.convertedError)
            enableFailedRelay.accept(coin)
        }
    }

    func onDisable(coin: Coin) {
        service.disable(coin: coin)
    }

    func onUpdate(filter: String?) {
        self.filter = filter

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.syncViewState()
        }
    }

}

extension CreateWalletViewModel {

    var createEnabledDriver: Driver<Bool> {
        service.canCreateObservable.asDriver(onErrorJustReturn: false)
    }

    var errorSignal: Signal<Error> {
        errorRelay.asSignal()
    }

    var enableFailedSignal: Signal<Coin> {
        enableFailedRelay.asSignal()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onCreate() {
        do {
            try service.create()
            finishRelay.accept(())
        } catch {
            errorRelay.accept(error.convertedError)
        }
    }

}
