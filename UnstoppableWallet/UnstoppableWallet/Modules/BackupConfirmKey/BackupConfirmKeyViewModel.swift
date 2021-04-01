import RxSwift
import RxRelay
import RxCocoa

class BackupConfirmKeyViewModel {
    private let service: BackupConfirmKeyService
    private let disposeBag = DisposeBag()

    private let indexViewItemRelay = BehaviorRelay<IndexViewItem>(value: IndexViewItem(first: "", second: ""))
    private let showErrorRelay = PublishRelay<String>()
    private let successRelay = PublishRelay<()>()

    init(service: BackupConfirmKeyService) {
        self.service = service

        subscribe(disposeBag, service.indexItemObservable) { [weak self] in self?.sync(indexItem: $0) }

        sync(indexItem: service.indexItem)
    }

    private func sync(indexItem: BackupConfirmKeyService.IndexItem) {
        let indexViewItem = IndexViewItem(first: "\(indexItem.first + 1).", second: "\(indexItem.second + 1).")
        indexViewItemRelay.accept(indexViewItem)
    }

}

extension BackupConfirmKeyViewModel {

    var indexViewItemDriver: Driver<IndexViewItem> {
        indexViewItemRelay.asDriver()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var successSignal: Signal<()> {
        successRelay.asSignal()
    }

    func onViewAppear() {
        service.generateIndexes()
    }

    func onTapDone(firstWord: String, secondWord: String) {
        do {
            try service.backup(firstWord: firstWord, secondWord: secondWord)
            successRelay.accept(())
        } catch {
            showErrorRelay.accept(error.smartDescription)
        }
    }

}

extension BackupConfirmKeyViewModel {

    struct IndexViewItem {
        let first: String
        let second: String
    }

}
