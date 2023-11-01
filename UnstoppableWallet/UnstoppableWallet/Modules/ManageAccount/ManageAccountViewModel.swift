import Foundation
import RxCocoa
import RxRelay
import RxSwift

class ManageAccountViewModel {
    private let service: ManageAccountService
    private let accountRestoreWarningFactory: AccountRestoreWarningFactory
    private let disposeBag = DisposeBag()

    private let keyActionsRelay = BehaviorRelay<[KeyActionSection]>(value: [])
    private let showWarningRelay = BehaviorRelay<CancellableTitledCaution?>(value: nil)
    private let saveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let openUnlockRelay = PublishRelay<Void>()
    private let openRecoveryPhraseRelay = PublishRelay<Account>()
    private let openBackupRelay = PublishRelay<Account>()
    private let openBackupAndDeleteCloudRelay = PublishRelay<Account>()
    private let openCloudBackupRelay = PublishRelay<Account>()
    private let confirmDeleteCloudBackupRelay = PublishRelay<Bool>()
    private let cloudBackupDeletedRelay = PublishRelay<Bool>()
    private let openUnlinkRelay = PublishRelay<Account>()
    private let finishRelay = PublishRelay<Void>()

    private var unlockRequest: UnlockRequest = .recoveryPhrase

    init(service: ManageAccountService, accountRestoreWarningFactory: AccountRestoreWarningFactory) {
        self.service = service
        self.accountRestoreWarningFactory = accountRestoreWarningFactory

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.accountObservable) { [weak self] in self?.sync(account: $0) }
        subscribe(disposeBag, service.cloudBackedUpObservable) { [weak self] in self?.sync() }
        subscribe(disposeBag, service.accountDeletedObservable) { [weak self] in self?.finishRelay.accept(()) }

        sync(state: service.state)
        sync()
    }

    private func sync(state: ManageAccountService.State) {
        switch state {
        case .cannotSave: saveEnabledRelay.accept(false)
        case .canSave: saveEnabledRelay.accept(true)
        }
    }

    private func keyActions(account: Account, isCloudBackedUp: Bool) -> [KeyActionSection] {
        var backupActions = [KeyAction]()

        var footerText = ""

        if account.canBeBackedUp {
            backupActions.append(.manualBackup(account.backedUp))
            footerText = !(account.backedUp || isCloudBackedUp) ?
                "manage_account.backup.no_backup_yet_description".localized :
                "manage_account.backup.has_backup_description".localized
        }

        if !account.watchAccount {
            backupActions.append(.cloudBackedUp(isCloudBackedUp, isManualBackedUp: account.backedUp))
        }

        let backupSection = KeyActionSection(keyActions: backupActions, footerText: footerText)
        guard account.backedUp || isCloudBackedUp else {
            return [backupSection]
        }

        var keyActions = [KeyAction]()
        switch account.type {
        case .mnemonic: keyActions.append(contentsOf: [.recoveryPhrase, .privateKeys, .publicKeys])
        case .evmPrivateKey: keyActions.append(contentsOf: [.privateKeys, .publicKeys])
        case .evmAddress, .tronAddress: ()
        case let .hdExtendedKey(key):
            switch key {
            case .private: keyActions.append(contentsOf: [.privateKeys, .publicKeys])
            case .public: keyActions.append(contentsOf: [.publicKeys])
            }
        case .cex: ()
        }

        var sections = [KeyActionSection]()

        if !keyActions.isEmpty {
            sections.append(KeyActionSection(keyActions: keyActions))
        }

        if !backupSection.keyActions.isEmpty {
            sections.append(backupSection)
        }

        return sections
    }

    private func sync(account: Account? = nil) {
        let account = account ?? service.account
        showWarningRelay.accept(accountRestoreWarningFactory.caution(account: account, canIgnoreActiveAccountWarning: false))
        keyActionsRelay.accept(keyActions(account: account, isCloudBackedUp: service.isCloudBackedUp))
    }
}

extension ManageAccountViewModel {
    var saveEnabledDriver: Driver<Bool> {
        saveEnabledRelay.asDriver()
    }

    var keyActionsDriver: Driver<[KeyActionSection]> {
        keyActionsRelay.asDriver()
    }

    var showWarningDriver: Driver<CancellableTitledCaution?> {
        showWarningRelay.asDriver()
    }

    var warningUrl: URL? {
        accountRestoreWarningFactory.warningUrl(account: service.account)
    }

    var openUnlockSignal: Signal<Void> {
        openUnlockRelay.asSignal()
    }

    var openRecoveryPhraseSignal: Signal<Account> {
        openRecoveryPhraseRelay.asSignal()
    }

    var openBackupSignal: Signal<Account> {
        openBackupRelay.asSignal()
    }

    var openBackupAndDeleteCloudSignal: Signal<Account> {
        openBackupAndDeleteCloudRelay.asSignal()
    }

    var openCloudBackupSignal: Signal<Account> {
        openCloudBackupRelay.asSignal()
    }

    var confirmDeleteCloudBackupSignal: Signal<Bool> {
        confirmDeleteCloudBackupRelay.asSignal()
    }

    var cloudBackupDeletedSignal: Signal<Bool> {
        cloudBackupDeletedRelay.asSignal()
    }

    var openUnlinkSignal: Signal<Account> {
        openUnlinkRelay.asSignal()
    }

    var finishSignal: Signal<Void> {
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
        case .backupToCloud: openCloudBackupRelay.accept(service.account)
        case .backupAndDeleteCloud: openBackupAndDeleteCloudRelay.accept(service.account)
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
        if service.isPasscodeSet {
            unlockRequest = .recoveryPhrase
            openUnlockRelay.accept(())
        } else {
            openRecoveryPhraseRelay.accept(service.account)
        }
    }

    func onTapDeleteCloudBackup() {
        confirmDeleteCloudBackupRelay.accept(service.account.backedUp)
    }

    func deleteCloudBackup() {
        do {
            try service.deleteCloudBackup()
            cloudBackupDeletedRelay.accept(true)
        } catch {
            cloudBackupDeletedRelay.accept(false)
        }
    }

    func deleteCloudBackupAfterManualBackup() {
        if service.isPasscodeSet {
            unlockRequest = .backupAndDeleteCloud
            openUnlockRelay.accept(())
        } else {
            openBackupAndDeleteCloudRelay.accept(service.account)
        }
    }

    func onTapCloudBackup() {
        if service.isPasscodeSet {
            unlockRequest = .backupToCloud
            openUnlockRelay.accept(())
        } else {
            openCloudBackupRelay.accept(service.account)
        }
    }

    func onTapBackup() {
        if service.isPasscodeSet {
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
        case backupToCloud
        case backupAndDeleteCloud
    }

    enum KeyAction {
        case recoveryPhrase
        case publicKeys
        case privateKeys
        case manualBackup(Bool)
        case cloudBackedUp(Bool, isManualBackedUp: Bool)
    }

    struct KeyActionSection {
        let keyActions: [KeyAction]
        let footerText: String

        init(keyActions: [KeyAction], footerText: String = "") {
            self.keyActions = keyActions
            self.footerText = footerText
        }
    }
}
