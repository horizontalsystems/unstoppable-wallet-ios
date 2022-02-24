import UIKit
import RxSwift
import RxCocoa
import MarketKit

class RestoreSelectViewModel {
    private let service: RestoreSelectService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[CoinToggleViewModel.ViewItem]>(value: [])
    private let disableBlockchainRelay = PublishRelay<String>()
    private let successRelay = PublishRelay<()>()

    init(service: RestoreSelectService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.cancelEnableBlockchainObservable) { [weak self] in self?.disableBlockchainRelay.accept($0.uid) }

        sync(items: service.items)
    }

    private func viewItem(item: RestoreSelectService.Item) -> CoinToggleViewModel.ViewItem {
        let viewItemState: CoinToggleViewModel.ViewItemState

        switch item.state {
        case let .supported(enabled, hasSettings): viewItemState = .toggleVisible(enabled: enabled, hasSettings: hasSettings)
        case .unsupported: viewItemState = .toggleHidden
        }

        return CoinToggleViewModel.ViewItem(
                uid: item.blockchain.uid,
                imageUrl: "",
                placeholderImageName: item.blockchain.imageName,
                title: item.blockchain.title,
                subtitle: item.blockchain.description,
                state: viewItemState,
                blockchainBadge: nil
        )
    }

    private func sync(items: [RestoreSelectService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
    }

}

extension RestoreSelectViewModel: ICoinToggleViewModel {

    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func onEnable(uid: String) {
        service.enable(blockchainUid: uid)
    }

    func onDisable(uid: String) {
        service.disable(blockchainUid: uid)
    }

    func onTapSettings(uid: String) {
        service.configure(blockchainUid: uid)
    }

    func onUpdate(filter: String) {
    }

}

extension RestoreSelectViewModel {

    var disableBlockchainSignal: Signal<String> {
        disableBlockchainRelay.asSignal()
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
