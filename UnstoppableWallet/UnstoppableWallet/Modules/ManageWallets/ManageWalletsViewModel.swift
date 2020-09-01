import RxSwift
import RxRelay
import RxCocoa

class ManageWalletsViewModel {
    private let service: ManageWalletsService

    private let disposeBag = DisposeBag()
    private let viewStateRelay = BehaviorRelay<ManageWalletsModule.ViewState>(value: .empty)
    private let openDerivationSettingsRelay = PublishRelay<(coin: Coin, currentDerivation: MnemonicDerivation)>()
    private var filter: String?

    init(service: ManageWalletsService) {
        self.service = service

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.syncViewState(state: state)
                })
                .disposed(by: disposeBag)

        syncViewState()
    }

    private func viewItem(item: ManageWalletsModule.Item) -> CoinToggleViewItem {
        let state: CoinToggleViewItemState

        switch item.state {
        case .noAccount:
            state = .toggleHidden
        case .hasAccount(let hasWallet):
            state = .toggleVisible(enabled: hasWallet)
        }

        return CoinToggleViewItem(
                coin: item.coin,
                state: state
        )
    }

    private func filtered(items: [ManageWalletsModule.Item]) -> [ManageWalletsModule.Item] {
        guard let filter = filter else {
            return items
        }

        return items.filter { item in
            item.coin.title.lowercased().contains(filter.lowercased()) || item.coin.code.lowercased().contains(filter.lowercased())
        }
    }

    private func syncViewState(state: ManageWalletsModule.State? = nil) {
        let state = state ?? service.state

        let viewState = ManageWalletsModule.ViewState(
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
        } catch let error as ManageWalletsService.EnableCoinError {
            switch error {
            case .derivationNotConfirmed(let currentDerivation):
                openDerivationSettingsRelay.accept((coin: coin, currentDerivation: currentDerivation))
            default: ()
            }
        } catch {
        }
    }

}

extension ManageWalletsViewModel {

    var viewStateDriver: Driver<ManageWalletsModule.ViewState> {
        viewStateRelay.asDriver()
    }

    var openDerivationSettingsSignal: Signal<(coin: Coin, currentDerivation: MnemonicDerivation)> {
        openDerivationSettingsRelay.asSignal()
    }

    func onEnable(coin: Coin) {
        enable(coin: coin)
    }

    func onDisable(coin: Coin) {
        service.disable(coin: coin)
    }

    func onSelect(derivationSetting: DerivationSetting, coin: Coin) {
        enable(coin: coin, derivationSetting: derivationSetting)
    }

    func onUpdate(filter: String?) {
        self.filter = filter

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.syncViewState()
        }
    }

}
