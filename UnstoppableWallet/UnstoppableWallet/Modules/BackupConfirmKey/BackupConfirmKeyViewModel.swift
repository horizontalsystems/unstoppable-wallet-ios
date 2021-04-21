import RxSwift
import RxRelay
import RxCocoa

class BackupConfirmKeyViewModel {
    private let service: BackupConfirmKeyService
    private let disposeBag = DisposeBag()

    private let indexViewItemRelay = BehaviorRelay<IndexViewItem>(value: IndexViewItem(first: 0, second: 0))
    private let firstWordCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let secondWordCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let passphraseCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let clearInputsRelay = PublishRelay<Void>()
    private let successRelay = PublishRelay<()>()

    init(service: BackupConfirmKeyService) {
        self.service = service

        subscribe(disposeBag, service.indexItemObservable) { [weak self] in self?.sync(indexItem: $0) }

        sync(indexItem: service.indexItem)
    }

    private func sync(indexItem: BackupConfirmKeyService.IndexItem) {
        let indexViewItem = IndexViewItem(first: indexItem.first + 1, second: indexItem.second + 1)
        indexViewItemRelay.accept(indexViewItem)
    }

    private func clearInputs() {
        clearInputsRelay.accept(())

        firstWordCautionRelay.accept(nil)
        secondWordCautionRelay.accept(nil)
        passphraseCautionRelay.accept(nil)

        service.firstWord = ""
        service.secondWord = ""
        service.passphrase = ""
    }

}

extension BackupConfirmKeyViewModel {

    var indexViewItemDriver: Driver<IndexViewItem> {
        indexViewItemRelay.asDriver()
    }

    var firstWordCautionDriver: Driver<Caution?> {
        firstWordCautionRelay.asDriver()
    }

    var secondWordCautionDriver: Driver<Caution?> {
        secondWordCautionRelay.asDriver()
    }

    var passphraseCautionDriver: Driver<Caution?> {
        passphraseCautionRelay.asDriver()
    }

    var clearInputsSignal: Signal<Void> {
        clearInputsRelay.asSignal()
    }

    var successSignal: Signal<()> {
        successRelay.asSignal()
    }

    var passphraseVisible: Bool {
        service.hasSalt
    }

    func onViewAppear() {
        service.generateIndexes()
        clearInputs()
    }

    func onChange(firstWord: String) {
        service.firstWord = firstWord
        firstWordCautionRelay.accept(nil)
    }

    func onChange(secondWord: String) {
        service.secondWord = secondWord
        secondWordCautionRelay.accept(nil)
    }

    func onChange(passphrase: String) {
        service.passphrase = passphrase
        passphraseCautionRelay.accept(nil)
    }

    func onTapDone() {
        do {
            try service.backup()
            successRelay.accept(())
        } catch {
            guard let backupError = error as? BackupConfirmKeyService.BackupError else {
                return
            }

            for validationError in backupError.validationErrors {
                switch validationError {
                case .emptyFirstWord: firstWordCautionRelay.accept(Caution(text: "backup_key.confirmation.empty_word".localized, type: .error))
                case .invalidFirstWord: firstWordCautionRelay.accept(Caution(text: "backup_key.confirmation.invalid_word".localized, type: .error))
                case .emptySecondWord: secondWordCautionRelay.accept(Caution(text: "backup_key.confirmation.empty_word".localized, type: .error))
                case .invalidSecondWord: secondWordCautionRelay.accept(Caution(text: "backup_key.confirmation.invalid_word".localized, type: .error))
                case .emptyPassphrase: passphraseCautionRelay.accept(Caution(text: "backup_key.confirmation.empty_passphrase".localized, type: .error))
                case .invalidPassphrase: passphraseCautionRelay.accept(Caution(text: "backup_key.confirmation.invalid_passphrase".localized, type: .error))
                }
            }
        }
    }

}

extension BackupConfirmKeyViewModel {

    struct IndexViewItem {
        let first: Int
        let second: Int
    }

}
