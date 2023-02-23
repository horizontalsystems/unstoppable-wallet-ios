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
        CoinToggleViewModel.ViewItem(
                uid: item.blockchain.uid,
                imageUrl: item.blockchain.type.imageUrl,
                placeholderImageName: "placeholder_rectangle_32",
                title: item.blockchain.name,
                subtitle: item.blockchain.type.description,
                badge: nil,
                state: .toggleVisible(enabled: item.enabled, hasSettings: item.hasSettings, hasInfo: false)
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

    func onTapInfo(uid: String) {
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
