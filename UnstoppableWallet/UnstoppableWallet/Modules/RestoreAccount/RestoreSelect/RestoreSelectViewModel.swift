import RxSwift
import RxCocoa
import MarketKit

class RestoreSelectViewModel {
    private let service: RestoreSelectService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[CoinToggleViewModel.ViewItem]>(value: [])
    private let disableCoinRelay = PublishRelay<Coin>()
    private let successRelay = PublishRelay<()>()

    init(service: RestoreSelectService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.cancelEnableCoinObservable) { [weak self] in self?.disableCoinRelay.accept($0) }

        sync(items: service.items)
    }

    private func viewItem(item: RestoreSelectService.Item) -> CoinToggleViewModel.ViewItem {
        let viewItemState: CoinToggleViewModel.ViewItemState

        switch item.state {
        case let .supported(enabled, hasSettings): viewItemState = .toggleVisible(enabled: enabled, hasSettings: hasSettings)
        case .unsupported: viewItemState = .toggleHidden
        }

        return CoinToggleViewModel.ViewItem(marketCoin: item.marketCoin, state: viewItemState)
    }

    private func sync(items: [RestoreSelectService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
    }

}

extension RestoreSelectViewModel: ICoinToggleViewModel {

    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func onEnable(marketCoin: MarketCoin) {
        service.enable(marketCoin: marketCoin)
    }

    func onDisable(coin: Coin) {
        service.disable(coin: coin)
    }

    func onTapSettings(marketCoin: MarketCoin) {
        service.configure(marketCoin: marketCoin)
    }

    func onUpdate(filter: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter)
        }
    }

}

extension RestoreSelectViewModel {

    var disableCoinSignal: Signal<Coin> {
        disableCoinRelay.asSignal()
    }

    var restoreEnabledDriver: Driver<Bool> {
        service.canRestoreObservable.asDriver(onErrorJustReturn: false)
    }

    var successSignal: Signal<()> {
        successRelay.asSignal()
    }

    func onRestore() {
        service.restore()
        successRelay.accept(())
    }

}
