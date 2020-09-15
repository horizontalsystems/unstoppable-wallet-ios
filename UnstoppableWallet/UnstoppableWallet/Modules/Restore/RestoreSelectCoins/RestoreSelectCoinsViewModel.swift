import RxSwift
import RxCocoa

class RestoreSelectCoinsViewModel {
    private let service: RestoreSelectCoinsService

    private let disposeBag = DisposeBag()
    private let viewStateRelay = BehaviorRelay<CoinToggleViewModel.ViewState>(value: .empty)
    private let openDerivationSettingsRelay = PublishRelay<(coin: Coin, currentDerivation: MnemonicDerivation)>()
    private let enabledCoinsRelay = PublishRelay<[Coin]>()
    private var filter: String?

    init(service: RestoreSelectCoinsService) {
        self.service = service

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.syncViewState(state: state)
                })
                .disposed(by: disposeBag)

        syncViewState()
    }

    private func viewItem(item: RestoreSelectCoinsService.Item) -> CoinToggleViewModel.ViewItem {
        CoinToggleViewModel.ViewItem(
                coin: item.coin,
                state: .toggleVisible(enabled: item.enabled)
        )
    }

    private func filtered(items: [RestoreSelectCoinsService.Item]) -> [RestoreSelectCoinsService.Item] {
        guard let filter = filter else {
            return items
        }

        return items.filter { item in
            item.coin.title.localizedCaseInsensitiveContains(filter) || item.coin.code.localizedCaseInsensitiveContains(filter)
        }
    }

    private func syncViewState(state: RestoreSelectCoinsService.State? = nil) {
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

    private func enable(coin: Coin, derivationSetting: DerivationSetting? = nil) {
        do {
            try service.enable(coin: coin, derivationSetting: derivationSetting)
        } catch let error as RestoreSelectCoinsService.EnableCoinError {
            switch error {
            case .derivationNotConfirmed(let currentDerivation):
                openDerivationSettingsRelay.accept((coin: coin, currentDerivation: currentDerivation))
            }
        } catch {
        }
    }

}

extension RestoreSelectCoinsViewModel: ICoinToggleViewModel {

    var viewStateDriver: Driver<CoinToggleViewModel.ViewState> {
        viewStateRelay.asDriver()
    }

    func onEnable(coin: Coin) {
        enable(coin: coin)
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

extension RestoreSelectCoinsViewModel {

    var restoreEnabledDriver: Driver<Bool> {
        service.canRestoreObservable.asDriver(onErrorJustReturn: false)
    }

    var enabledCoinsSignal: Signal<[Coin]> {
        enabledCoinsRelay.asSignal()
    }

    var openDerivationSettingsSignal: Signal<(coin: Coin, currentDerivation: MnemonicDerivation)> {
        openDerivationSettingsRelay.asSignal()
    }

    func onSelect(derivationSetting: DerivationSetting, coin: Coin) {
        enable(coin: coin, derivationSetting: derivationSetting)
    }

    func onRestore() {
        enabledCoinsRelay.accept(Array(service.enabledCoins))
    }

}
