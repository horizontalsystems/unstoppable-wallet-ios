import RxSwift
import RxRelay
import RxCocoa
import BitcoinCashKit

class ManageWalletsViewModel {
    private let service: ManageWalletsService

    private let disposeBag = DisposeBag()
    private let viewStateRelay = BehaviorRelay<CoinToggleViewModel.ViewState>(value: .empty)
    private let enableCoinRelay = PublishRelay<Coin>()
    private let disableCoinRelay = PublishRelay<Coin>()
    private var filter: String?

    init(service: ManageWalletsService) {
        self.service = service

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.syncViewState(state: state)
                })
                .disposed(by: disposeBag)

        service.enableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.enableCoinRelay.accept(coin)
                })
                .disposed(by: disposeBag)

        service.cancelEnableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.disableCoinRelay.accept(coin)
                })
                .disposed(by: disposeBag)

        syncViewState()
    }

    private func viewItem(item: ManageWalletsService.Item) -> CoinToggleViewModel.ViewItem {
        let state: CoinToggleViewModel.ViewItemState

        switch item.state {
        case .noAccount:
            state = .toggleHidden
        case .hasAccount(_, let hasWallet):
            state = .toggleVisible(enabled: hasWallet)
        }

        return CoinToggleViewModel.ViewItem(
                coin: item.coin,
                state: state
        )
    }

    private func filtered(items: [ManageWalletsService.Item]) -> [ManageWalletsService.Item] {
        guard let filter = filter else {
            return items
        }

        return items.filter { item in
            item.coin.title.localizedCaseInsensitiveContains(filter) || item.coin.code.localizedCaseInsensitiveContains(filter)
        }
    }

    private func syncViewState(state: ManageWalletsService.State? = nil) {
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

extension ManageWalletsViewModel: ICoinToggleViewModel {

    var viewStateDriver: Driver<CoinToggleViewModel.ViewState> {
        viewStateRelay.asDriver()
    }

    func onEnable(coin: Coin) {
        service.enable(coin: coin)
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

extension ManageWalletsViewModel {

    var disableCoinSignal: Signal<Coin> {
        disableCoinRelay.asSignal()
    }

    var enableCoinSignal: Signal<Coin> {
        enableCoinRelay.asSignal()
    }

    func onAddAccount(coin: Coin) {
        service.storeCoinToEnable(coin: coin)
    }

}
