import Foundation
import RxSwift
import RxRelay
import RxCocoa

class ManageAccountViewModel {
    private let service: ManageAccountService
    private let accountRestoreWarningFactory: AccountRestoreWarningFactory
    private let disposeBag = DisposeBag()

    private let keyActionsRelay = BehaviorRelay<[KeyAction]>(value: [])
    private let showWarningRelay = BehaviorRelay<CancellableTitledCaution?>(value: nil)
    private let saveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let openUnlockRelay = PublishRelay<()>()
    private let openRecoveryPhraseRelay = PublishRelay<Account>()
    private let openBackupRelay = PublishRelay<Account>()
    private let openUnlinkRelay = PublishRelay<Account>()
    private let finishRelay = PublishRelay<()>()

    private var unlockRequest: UnlockRequest = .recoveryPhrase

    init(service: ManageAccountService, accountRestoreWarningFactory: AccountRestoreWarningFactory) {
        self.service = service
        self.accountRestoreWarningFactory = accountRestoreWarningFactory

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

    private func keyActions(account: Account) -> [KeyAction] {
        guard account.backedUp else {
            return [.backup]
        }

        switch account.type {
        case .mnemonic: return [.recoveryPhrase, .privateKeys, .publicKeys]
        case .evmPrivateKey: return [.privateKeys, .publicKeys]
        case .evmAddress: return [.publicKeys]
        case .hdExtendedKey(let key):
            switch key {
            case .private: return [.privateKeys, .publicKeys]
            case .public: return [.publicKeys]
            }
        }
    }

    private func sync(account: Account) {
        showWarningRelay.accept(accountRestoreWarningFactory.caution(account: account, canIgnoreActiveAccountWarning: false))
        keyActionsRelay.accept(keyActions(account: account))
    }

}

extension ManageAccountViewModel {

    var saveEnabledDriver: Driver<Bool> {
        saveEnabledRelay.asDriver()
    }

    var keyActionsDriver: Driver<[KeyAction]> {
        keyActionsRelay.asDriver()
    }

    var showWarningDriver: Driver<CancellableTitledCaution?> {
        showWarningRelay.asDriver()
    }

    var warningUrl: URL? {
        accountRestoreWarningFactory.warningUrl(account: service.account)
    }

    var openUnlockSignal: Signal<()> {
        openUnlockRelay.asSignal()
    }

    var openRecoveryPhraseSignal: Signal<Account> {
        openRecoveryPhraseRelay.asSignal()
    }

    var openBackupSignal: Signal<Account> {
        openBackupRelay.asSignal()
    }

    var openUnlinkSignal: Signal<Account> {
        openUnlinkRelay.asSignal()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var accountName: String {
        service.account.name
    }

    var account: Account {
        service.account
    }

    func onUnlock() {
        switch unlockRequest {
        case .recoveryPhrase: openRecoveryPhraseRelay.accept(service.account)
        case .backup: openBackupRelay.accept(service.account)
        }
    }

    func onChange(name: String?) {
        service.set(name: name ?? "")
    }

    func onSave() {
        service.saveAccount()
        finishRelay.accept(())
    }

    func onTapRecoveryPhrase() {
        if service.isPinSet {
            unlockRequest = .recoveryPhrase
            openUnlockRelay.accept(())
        } else {
            openRecoveryPhraseRelay.accept(service.account)
        }
    }

    func onTapBackup() {
        if service.isPinSet {
            unlockRequest = .backup
            openUnlockRelay.accept(())
        } else {
            openBackupRelay.accept(service.account)
        }
    }

    func onTapUnlink() {
        openUnlinkRelay.accept(service.account)
    }

}

extension ManageAccountViewModel {

    enum UnlockRequest {
        case recoveryPhrase
        case backup
    }

    enum KeyAction {
        case recoveryPhrase
        case publicKeys
        case privateKeys
        case backup
    }

}
