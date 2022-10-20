import RxSwift
import RxRelay
import RxCocoa

class ManageAccountViewModel {
    private let service: ManageAccountService
    private let disposeBag = DisposeBag()

    private let keyActionGroupsRelay = BehaviorRelay<[[KeyAction]]>(value: [])
    private let saveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let openUnlockRelay = PublishRelay<()>()
    private let openRecoveryPhraseRelay = PublishRelay<Account>()
    private let openEvmPrivateKeyRelay = PublishRelay<Account>()
    private let openBip32RootKeyRelay = PublishRelay<Account>()
    private let openAccountExtendedPrivateKeyRelay = PublishRelay<Account>()
    private let openAccountExtendedPublicKeyRelay = PublishRelay<Account>()
    private let openBackupRelay = PublishRelay<Account>()
    private let openUnlinkRelay = PublishRelay<Account>()
    private let finishRelay = PublishRelay<()>()

    private(set) var additionalViewItems = [AdditionalViewItem]()

    private var unlockRequest: UnlockRequest = .recoveryPhrase

    init(service: ManageAccountService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.accountObservable) { [weak self] in self?.sync(account: $0) }
        subscribe(disposeBag, service.accountDeletedObservable) { [weak self] in self?.finishRelay.accept(()) }

        sync(state: service.state)
        sync(account: service.account)
        syncAccountSettings()
    }

    private func sync(state: ManageAccountService.State) {
        switch state {
        case .cannotSave: saveEnabledRelay.accept(false)
        case .canSave: saveEnabledRelay.accept(true)
        }
    }

    private func keyActionGroups(account: Account) -> [[KeyAction]] {
        guard account.backedUp else {
            return [[.backupRecoveryPhrase]]
        }

        switch account.type {
        case .mnemonic: return [[.showRecoveryPhrase], [.showEvmPrivateKey], [.showBip32RootKey, .showAccountExtendedPrivateKey, .showAccountExtendedPublicKey]]
        case .evmPrivateKey: return [[.showEvmPrivateKey]]
        case .evmAddress: return []
        case .hdExtendedKey(let key):
            switch key {
            case .private:
                switch key.derivedType {
                case .master: return [[.showBip32RootKey, .showAccountExtendedPrivateKey, .showAccountExtendedPublicKey]]
                case .account: return [[.showAccountExtendedPrivateKey, .showAccountExtendedPublicKey]]
                default: return []
                }
            case .public:
                return [[.showAccountExtendedPublicKey]]
            }
        }
    }

    private func sync(account: Account) {
        keyActionGroupsRelay.accept(keyActionGroups(account: account))
    }

    private func syncAccountSettings() {
        additionalViewItems = service.accountSettingsInfo.map { coin, restoreSettingType, value in
            AdditionalViewItem(
                    imageUrl: coin.imageUrl,
                    title: restoreSettingType.title(coin: coin),
                    value: value
            )
        }
    }

}

extension ManageAccountViewModel {

    var saveEnabledDriver: Driver<Bool> {
        saveEnabledRelay.asDriver()
    }

    var keyActionGroupsDriver: Driver<[[KeyAction]]> {
        keyActionGroupsRelay.asDriver()
    }

    var openUnlockSignal: Signal<()> {
        openUnlockRelay.asSignal()
    }

    var openRecoveryPhraseSignal: Signal<Account> {
        openRecoveryPhraseRelay.asSignal()
    }

    var openEvmPrivateKeySignal: Signal<Account> {
        openEvmPrivateKeyRelay.asSignal()
    }

    var openBip32RootKeySignal: Signal<Account> {
        openBip32RootKeyRelay.asSignal()
    }

    var openAccountExtendedPrivateKeySignal: Signal<Account> {
        openAccountExtendedPrivateKeyRelay.asSignal()
    }

    var openAccountExtendedPublicKeySignal: Signal<Account> {
        openAccountExtendedPublicKeyRelay.asSignal()
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

    func onUnlock() {
        switch unlockRequest {
        case .recoveryPhrase: openRecoveryPhraseRelay.accept(service.account)
        case .evmPrivateKey: openEvmPrivateKeyRelay.accept(service.account)
        case .bip32RootKey: openBip32RootKeyRelay.accept(service.account)
        case .accountExtendedPrivateKey: openAccountExtendedPrivateKeyRelay.accept(service.account)
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

    func onTapEvmPrivateKey() {
        if service.isPinSet {
            unlockRequest = .evmPrivateKey
            openUnlockRelay.accept(())
        } else {
            openEvmPrivateKeyRelay.accept(service.account)
        }
    }

    func onTapBip32RootKey() {
        if service.isPinSet {
            unlockRequest = .bip32RootKey
            openUnlockRelay.accept(())
        } else {
            openBip32RootKeyRelay.accept(service.account)
        }
    }

    func onTapAccountExtendedPrivateKey() {
        if service.isPinSet {
            unlockRequest = .accountExtendedPrivateKey
            openUnlockRelay.accept(())
        } else {
            openAccountExtendedPrivateKeyRelay.accept(service.account)
        }
    }

    func onTapAccountExtendedPublicKey() {
        openAccountExtendedPublicKeyRelay.accept(service.account)
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
        case evmPrivateKey
        case bip32RootKey
        case accountExtendedPrivateKey
        case backup
    }

    enum KeyAction {
        case showRecoveryPhrase
        case showEvmPrivateKey
        case showBip32RootKey
        case showAccountExtendedPrivateKey
        case showAccountExtendedPublicKey
        case backupRecoveryPhrase
    }

    struct AdditionalViewItem {
        let imageUrl: String
        let title: String
        let value: String
    }

}
