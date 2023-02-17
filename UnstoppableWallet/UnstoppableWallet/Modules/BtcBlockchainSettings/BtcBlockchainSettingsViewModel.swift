import RxSwift
import RxRelay
import RxCocoa

class BtcBlockchainSettingsViewModel {
    private let service: BtcBlockchainSettingsService
    private let disposeBag = DisposeBag()

    private let restoreModeViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let finishRelay = PublishRelay<()>()

    init(service: BtcBlockchainSettingsService) {
        self.service = service

        syncRestoreModeState()
    }

    private func syncRestoreModeState() {
        let viewItems = BtcRestoreMode.allCases.map { mode in
            ViewItem(name: mode.title, description: mode.description, selected: mode == service.restoreMode)
        }
        restoreModeViewItemsRelay.accept(viewItems)
    }

}

extension BtcBlockchainSettingsViewModel {

    var restoreModeViewItemsDriver: Driver<[ViewItem]> {
        restoreModeViewItemsRelay.asDriver()
    }

    var canSaveDriver: Driver<Bool> {
        service.hasChangesObservable.asDriver(onErrorJustReturn: false)
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var title: String {
        service.blockchain.name
    }

    var iconUrl: String {
        service.blockchain.type.imageUrl
    }

    func onSelectRestoreMode(index: Int) {
        service.restoreMode = BtcRestoreMode.allCases[index]
        syncRestoreModeState()
    }

    func onTapSave() {
        service.save()
        finishRelay.accept(())
    }

}

extension BtcBlockchainSettingsViewModel {

    struct ViewItem {
        let name: String
        let description: String
        let selected: Bool
    }

}
