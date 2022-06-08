import RxSwift
import RxRelay
import RxCocoa

class BtcBlockchainSettingsViewModel {
    private let service: BtcBlockchainSettingsService
    private let disposeBag = DisposeBag()

    private let restoreModeViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let transactionModeViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let finishRelay = PublishRelay<()>()

    init(service: BtcBlockchainSettingsService) {
        self.service = service

        syncRestoreModeState()
        syncTransactionModeState()
    }

    private func syncRestoreModeState() {
        let viewItems = BtcRestoreMode.allCases.map { mode in
            ViewItem(name: mode.title, description: mode.description, selected: mode == service.restoreMode)
        }
        restoreModeViewItemsRelay.accept(viewItems)
    }

    private func syncTransactionModeState() {
        let viewItems = TransactionDataSortMode.allCases.map { mode in
            ViewItem(name: mode.title, description: mode.description, selected: mode == service.transactionMode)
        }
        transactionModeViewItemsRelay.accept(viewItems)
    }

}

extension BtcBlockchainSettingsViewModel {

    var restoreModeViewItemsDriver: Driver<[ViewItem]> {
        restoreModeViewItemsRelay.asDriver()
    }

    var transactionModeViewItemsDriver: Driver<[ViewItem]> {
        transactionModeViewItemsRelay.asDriver()
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

    func onSelectTransactionMode(index: Int) {
        service.transactionMode = TransactionDataSortMode.allCases[index]
        syncTransactionModeState()
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
