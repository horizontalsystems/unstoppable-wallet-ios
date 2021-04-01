import RxSwift
import RxRelay
import RxCocoa

class ManageAccountViewModel {
    private let service: ManageAccountService
    private let disposeBag = DisposeBag()

    private let keyActionStateRelay = BehaviorRelay<KeyActionState>(value: .showRecoveryPhrase)
    private let saveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let openShowKeyRelay = PublishRelay<Account>()
    private let openBackupKeyRelay = PublishRelay<Account>()
    private let openUnlinkRelay = PublishRelay<Account>()
    private let openBackupRequiredRelay = PublishRelay<Account>()
    private let finishRelay = PublishRelay<()>()

    init(service: ManageAccountService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.accountObservable) { [weak self] in self?.sync(account: $0) }
        subscribe(disposeBag, service.accountDeletedObservable) { [weak self] in self?.finishRelay.accept(()) }

        sync(state: service.state)
        sync(account: service.account)
    }

    private func sync(state: ManageAccountService.State) {
        switch state {
        case .cannotSave: saveEnabledRelay.accept(false)
        case .canSave: saveEnabledRelay.accept(true)
        }
    }

    private func sync(account: Account) {
        keyActionStateRelay.accept(account.backedUp ? .showRecoveryPhrase : .backupRecoveryPhrase)
    }

}

extension ManageAccountViewModel {

    var saveEnabledDriver: Driver<Bool> {
        saveEnabledRelay.asDriver()
    }

    var keyActionStateDriver: Driver<KeyActionState> {
        keyActionStateRelay.asDriver()
    }

    var openShowKeySignal: Signal<Account> {
        openShowKeyRelay.asSignal()
    }

    var openBackupKeySignal: Signal<Account> {
        openBackupKeyRelay.asSignal()
    }

    var openUnlinkSignal: Signal<Account> {
        openUnlinkRelay.asSignal()
    }

    var openBackupRequiredSignal: Signal<Account> {
        openBackupRequiredRelay.asSignal()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var accountName: String {
        service.account.name
    }

    func isValid(name: String?) -> Bool {
        !(name ?? "").contains("\n")
    }

    func onChange(name: String?) {
        service.set(name: name ?? "")
    }

    func onSave() {
        service.saveAccount()
        finishRelay.accept(())
    }

    func onTapShowKey() {
        openShowKeyRelay.accept(service.account)
    }

    func onTapBackupKey() {
        openBackupKeyRelay.accept(service.account)
    }

    func onTapUnlink() {
        let account = service.account

        if account.backedUp {
            openUnlinkRelay.accept(account)
        } else {
            openBackupRequiredRelay.accept(account)
        }
    }

}

extension ManageAccountViewModel {

    enum KeyActionState {
        case showRecoveryPhrase
        case backupRecoveryPhrase
    }

}
