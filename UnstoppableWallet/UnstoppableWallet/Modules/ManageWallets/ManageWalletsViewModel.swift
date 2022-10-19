import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class ManageWalletsViewModel {
    private let service: ManageWalletsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[CoinToggleViewModel.ViewItem]>(value: [])
    private let notFoundVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let disableCoinRelay = PublishRelay<Coin>()

    init(service: ManageWalletsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.cancelEnableCoinObservable) { [weak self] in self?.disableCoinRelay.accept($0) }

        sync(items: service.items)
    }

    private func viewItem(item: ManageWalletsService.Item) -> CoinToggleViewModel.ViewItem {
        let viewItemState: CoinToggleViewModel.ViewItemState

        switch item.state {
        case let .supported(enabled, hasSettings): viewItemState = .toggleVisible(enabled: enabled, hasSettings: hasSettings)
        case .unsupported: viewItemState = .toggleHidden
        }

        return CoinToggleViewModel.ViewItem(
                uid: item.fullCoin.coin.uid,
                imageUrl: item.fullCoin.coin.imageUrl,
                placeholderImageName: item.fullCoin.placeholderImageName,
                title: item.fullCoin.coin.code,
                subtitle: item.fullCoin.coin.name,
                state: viewItemState
        )
    }

    private func sync(items: [ManageWalletsService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
        notFoundVisibleRelay.accept(items.isEmpty)
    }

}

extension ManageWalletsViewModel: ICoinToggleViewModel {

    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func onEnable(uid: String) {
        service.enable(uid: uid)
    }

    func onDisable(uid: String) {
        service.disable(uid: uid)
    }

    func onTapSettings(uid: String) {
        service.configure(uid: uid)
    }

    func onUpdate(filter: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter)
        }
    }

}

extension ManageWalletsViewModel {

    var notFoundVisibleDriver: Driver<Bool> {
        notFoundVisibleRelay.asDriver()
    }

    var disableCoinSignal: Signal<Coin> {
        disableCoinRelay.asSignal()
    }

    var accountTypeDescription: String {
        service.accountType.description
    }

    var addTokenEnabled: Bool {
        service.accountType.canAddTokens
    }

}
