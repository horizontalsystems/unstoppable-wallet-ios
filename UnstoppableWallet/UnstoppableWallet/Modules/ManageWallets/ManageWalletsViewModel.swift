import RxSwift
import RxRelay
import RxCocoa
import CoinKit

class ManageWalletsViewModel {
    private let service: ManageWalletsService
    private let disposeBag = DisposeBag()

    private let viewStateRelay = BehaviorRelay<CoinToggleViewModel.ViewState>(value: .empty)
    private let disableCoinRelay = PublishRelay<Coin>()

    init(service: ManageWalletsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] state in
            self?.syncViewState(state: state)
        }
        subscribe(disposeBag, service.cancelEnableCoinObservable) { [weak self] coin in
            self?.disableCoinRelay.accept(coin)
        }

        syncViewState()
    }

    private func viewItem(item: ManageWalletsService.Item) -> CoinToggleViewModel.ViewItem {
        CoinToggleViewModel.ViewItem(
                coin: item.coin,
                hasSettings: item.hasSettings,
                enabled: item.enabled
        )
    }

    private func syncViewState(state: ManageWalletsService.State? = nil) {
        let state = state ?? service.state

        let viewState = CoinToggleViewModel.ViewState(
                featuredViewItems: state.featuredItems.map { viewItem(item: $0) },
                viewItems: state.items.map { viewItem(item: $0) }
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

    func onTapSettings(coin: Coin) {
        service.configure(coin: coin)
    }

    func onUpdate(filter: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter)
        }
    }

}

extension ManageWalletsViewModel {

    var disableCoinSignal: Signal<Coin> {
        disableCoinRelay.asSignal()
    }

}
